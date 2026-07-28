package main

import (
	"context"
	"log"
	"net/http"
	"os"
	"time"

	"messaging/relay_server/server"
)

func main() {
	addr := getenv("RELAY_BIND_ADDR", ":8080")
	dbPath := getenv("RELAY_DB_PATH", "./relay.db")
	heartbeat := getenvDuration("RELAY_HEARTBEAT_INTERVAL", 30*time.Second)
	queueTTL := getenvDuration("RELAY_QUEUE_TTL", 72*time.Hour)
	bootstrapToken := os.Getenv("RELAY_BOOTSTRAP_TOKEN")
	if bootstrapToken == "" {
		log.Fatal("RELAY_BOOTSTRAP_TOKEN is required")
	}

	store, err := server.NewSQLiteStore(dbPath)
	if err != nil {
		log.Fatal(err)
	}
	defer store.Close()

	relay := server.NewRelay(server.Config{
		HeartbeatInterval: heartbeat,
		QueueTTL:          queueTTL,
		BootstrapToken:     bootstrapToken,
	}, store)

	mux := http.NewServeMux()
	mux.HandleFunc("/health", relay.HealthHandler)
	mux.HandleFunc("/status", relay.StatusHandler)
	mux.HandleFunc("/ws", relay.WebSocketHandler)

	srv := &http.Server{
		Addr:              addr,
		Handler:           mux,
		ReadHeaderTimeout: 10 * time.Second,
	}

	go func() {
		<-context.Background().Done()
		_ = srv.Shutdown(context.Background())
	}()

	log.Printf("relay server listening on %s", addr)
	if err := srv.ListenAndServe(); err != nil && err != http.ErrServerClosed {
		log.Fatal(err)
	}
}

func getenv(key, fallback string) string {
	if value := os.Getenv(key); value != "" {
		return value
	}
	return fallback
}

func getenvDuration(key string, fallback time.Duration) time.Duration {
	if value := os.Getenv(key); value != "" {
		if parsed, err := time.ParseDuration(value); err == nil {
			return parsed
		}
	}
	return fallback
}