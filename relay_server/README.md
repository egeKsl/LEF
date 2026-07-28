# Relay Server

Small Go WebSocket relay for SecureLink-style fingerprint routing.

## Environment

- `RELAY_BIND_ADDR` - listen address, default `:8080`
- `RELAY_DB_PATH` - SQLite path, default `./relay.db`
- `RELAY_BOOTSTRAP_TOKEN` - bootstrap token required for registration
- `RELAY_HEARTBEAT_INTERVAL` - heartbeat interval, default `30s`
- `RELAY_QUEUE_TTL` - queue retention, default `72h`

## Endpoints

- `GET /health`
- `GET /status`
- `GET /ws`
