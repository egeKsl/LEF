package server

import (
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"log"
	"net/http"
	"sync"
	"time"

	"github.com/coder/websocket"
)

type Relay struct {
	config Config
	store  *SQLiteStore

	mu        sync.RWMutex
	clients   map[string]*clientConn
	acceptOpts websocket.AcceptOptions
	startedAt  time.Time
	stopCh     chan struct{}
	statusOnce sync.Once
}

type clientConn struct {
	fingerprint string
	conn        *websocket.Conn
	mu          sync.Mutex
	lastSeen    time.Time
	closed      bool
	writeMu     sync.Mutex
	queueCount  int
}

func NewRelay(config Config, store *SQLiteStore) *Relay {
	return &Relay{
		config:   config,
		store:    store,
		clients:  make(map[string]*clientConn),
		acceptOpts: websocket.AcceptOptions{},
		startedAt: time.Now().UTC(),
		stopCh:   make(chan struct{}),
	}
}

func (r *Relay) HealthHandler(w http.ResponseWriter, _ *http.Request) {
	w.Header().Set("Content-Type", "application/json")
	_, _ = w.Write([]byte(`{"ok":true}`))
}

func (r *Relay) StatusHandler(w http.ResponseWriter, _ *http.Request) {
	r.mu.RLock()
	connected := len(r.clients)
	r.mu.RUnlock()
	queued, _ := r.store.CountQueued()
	registered, _ := r.store.CountRegistered()
	_ = json.NewEncoder(w).Encode(StatusResponse{
		ConnectedClients: connected,
		QueuedMessages:   queued,
		PendingMessages:  registered,
	})
}

func (r *Relay) WebSocketHandler(w http.ResponseWriter, req *http.Request) {
	conn, err := websocket.Accept(w, req, &r.acceptOpts)
	if err != nil {
		http.Error(w, err.Error(), http.StatusBadRequest)
		return
	}
	go r.handleConn(req.Context(), conn)
}

func (r *Relay) handleConn(ctx context.Context, conn *websocket.Conn) {
	defer conn.Close(websocket.StatusNormalClosure, "")

	_, data, err := conn.Read(ctx)
	if err != nil {
		return
	}
	var req RegisterRequest
	if err := json.Unmarshal(data, &req); err != nil || req.Type != "register" {
		_ = r.writeJSON(ctx, conn, RegisterAck{Type: "register_ack", OK: false, Error: "invalid_register", ProtocolVersion: ProtocolVersion})
		return
	}
	if req.ProtocolVersion != ProtocolVersion {
		_ = r.writeJSON(ctx, conn, RegisterAck{Type: "register_ack", OK: false, Error: "unsupported_protocol", ProtocolVersion: ProtocolVersion})
		return
	}
	if req.Token == "" || req.Fingerprint == "" {
		_ = r.writeJSON(ctx, conn, RegisterAck{Type: "register_ack", OK: false, Error: "missing_credentials", ProtocolVersion: ProtocolVersion})
		return
	}
	if req.Token != r.config.BootstrapToken {
		_ = r.writeJSON(ctx, conn, RegisterAck{Type: "register_ack", OK: false, Error: "invalid_token", ProtocolVersion: ProtocolVersion})
		return
	}
	if err := r.store.RegisterClient(req.Fingerprint, req.Token); err != nil {
		_ = r.writeJSON(ctx, conn, RegisterAck{Type: "register_ack", OK: false, Error: "store_failed", ProtocolVersion: ProtocolVersion})
		return
	}
	client := &clientConn{fingerprint: req.Fingerprint, conn: conn, lastSeen: time.Now().UTC()}
	r.registerClient(client)
	queued, _ := r.store.PendingForRecipient(req.Fingerprint)
	_ = r.writeJSON(ctx, conn, RegisterAck{Type: "register_ack", OK: true, HeartbeatSec: int64(r.config.HeartbeatInterval.Seconds()), QueueCount: len(queued), ProtocolVersion: ProtocolVersion})
	for _, env := range queued {
		_ = r.writeJSON(ctx, conn, env)
	}
	defer r.unregisterClient(req.Fingerprint)

	heartbeatTicker := time.NewTicker(r.config.HeartbeatInterval)
	defer heartbeatTicker.Stop()

	for {
		select {
		case <-ctx.Done():
			return
		case <-heartbeatTicker.C:
			_ = r.writeJSON(ctx, conn, Heartbeat{Type: "heartbeat", Now: time.Now().UTC().Format(time.RFC3339Nano), ProtocolVersion: ProtocolVersion})
		}
		_, payload, err := conn.Read(ctx)
		if err != nil {
			return
		}
		client.lastSeen = time.Now().UTC()
		r.routeMessage(ctx, conn, req.Fingerprint, payload)
	}
}

func (r *Relay) routeMessage(ctx context.Context, conn *websocket.Conn, sender string, payload []byte) {
	var env Envelope
	if err := json.Unmarshal(payload, &env); err != nil || env.Type != "envelope" {
		return
	}
	if env.ProtocolVersion != ProtocolVersion || env.Sender != sender || env.ID == "" || env.Recipient == "" {
		_ = r.writeJSON(ctx, conn, Undelivered{Type: "undelivered", ID: env.ID, Reason: "invalid_envelope", ProtocolVersion: ProtocolVersion})
		return
	}
	if err := r.store.QueueEnvelope(env); err != nil {
		_ = r.writeJSON(ctx, conn, Undelivered{Type: "undelivered", ID: env.ID, Reason: "queue_failed", ProtocolVersion: ProtocolVersion})
		return
	}

	r.mu.RLock()
	recipientConn := r.clients[env.Recipient]
	r.mu.RUnlock()
	if recipientConn == nil {
		_ = r.writeJSON(ctx, conn, Ack{Type: "ack", ID: env.ID, Status: "queued", ProtocolVersion: ProtocolVersion})
		return
	}
	if err := r.writeJSON(ctx, recipientConn.conn, env); err != nil {
		_ = r.writeJSON(ctx, conn, Ack{Type: "ack", ID: env.ID, Status: "queued", ProtocolVersion: ProtocolVersion})
		return
	}
	_ = r.store.MarkDelivered(env.ID)
	_ = r.writeJSON(ctx, conn, Ack{Type: "ack", ID: env.ID, Status: "delivered", ProtocolVersion: ProtocolVersion})
}

func (r *Relay) registerClient(client *clientConn) {
	r.mu.Lock()
	defer r.mu.Unlock()
	r.clients[client.fingerprint] = client
}

func (r *Relay) unregisterClient(fingerprint string) {
	r.mu.Lock()
	defer r.mu.Unlock()
	delete(r.clients, fingerprint)
}

func (r *Relay) writeJSON(ctx context.Context, conn *websocket.Conn, value any) error {
	connWriteCtx, cancel := context.WithTimeout(ctx, 5*time.Second)
	defer cancel()
	data, err := json.Marshal(value)
	if err != nil {
		return err
	}
	return conn.Write(connWriteCtx, websocket.MessageText, data)
}

func (r *Relay) StartCleanupLoop(ctx context.Context) {
	ticker := time.NewTicker(1 * time.Minute)
	defer ticker.Stop()
	for {
		select {
		case <-ctx.Done():
			return
		case <-ticker.C:
			if r.config.QueueTTL > 0 {
				_, err := r.store.CleanupExpired(r.config.QueueTTL)
				if err != nil {
					log.Printf("cleanup failed: %v", err)
				}
			}
		}
	}
}

func (r *Relay) Stop() {
	r.statusOnce.Do(func() { close(r.stopCh) })
}

func (r *Relay) ErrorResponse(err error) error {
	if err == nil {
		return nil
	}
	return errors.New(fmt.Sprintf("relay error: %v", err))
}