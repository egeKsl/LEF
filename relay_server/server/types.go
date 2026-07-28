package server

import "time"

const ProtocolVersion = 1

type Config struct {
	HeartbeatInterval time.Duration
	QueueTTL          time.Duration
	BootstrapToken    string
}

type RegisterRequest struct {
	Type            string `json:"type"`
	ProtocolVersion int    `json:"protocol_version"`
	Fingerprint     string `json:"fingerprint"`
	Token           string `json:"token"`
}

type RegisterAck struct {
	Type            string `json:"type"`
	OK              bool   `json:"ok"`
	Error           string `json:"error,omitempty"`
	HeartbeatSec    int64  `json:"heartbeat_sec"`
	QueueCount      int    `json:"queue_count"`
	ProtocolVersion int    `json:"protocol_version"`
}

type Envelope struct {
	Type            string `json:"type"`
	ProtocolVersion int    `json:"protocol_version"`
	ID              string `json:"id"`
	Sender          string `json:"sender"`
	Recipient       string `json:"recipient"`
	Payload         string `json:"payload"`
	Timestamp       string `json:"timestamp"`
}

type Ack struct {
	Type            string `json:"type"`
	ID              string `json:"id"`
	Status          string `json:"status"`
	Error           string `json:"error,omitempty"`
	ProtocolVersion int    `json:"protocol_version"`
}

type Undelivered struct {
	Type            string `json:"type"`
	ID              string `json:"id"`
	Reason          string `json:"reason"`
	ProtocolVersion int    `json:"protocol_version"`
}

type Heartbeat struct {
	Type            string `json:"type"`
	Now             string `json:"now"`
	ProtocolVersion int    `json:"protocol_version"`
}

type StatusResponse struct {
	ConnectedClients int `json:"connected_clients"`
	QueuedMessages   int `json:"queued_messages"`
	PendingMessages  int `json:"pending_messages"`
}

type storedEnvelope struct {
	ID        string
	Sender    string
	Recipient string
	Payload   string
	Timestamp time.Time
	State     string
}