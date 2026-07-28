package server

import (
	"database/sql"
	"errors"
	"fmt"
	"time"

	_ "modernc.org/sqlite"
)

type SQLiteStore struct {
	db *sql.DB
}

func NewSQLiteStore(path string) (*SQLiteStore, error) {
	db, err := sql.Open("sqlite", path)
	if err != nil {
		return nil, err
	}
	if _, err := db.Exec(`PRAGMA journal_mode=WAL; PRAGMA foreign_keys=ON; PRAGMA busy_timeout=5000;`); err != nil {
		_ = db.Close()
		return nil, err
	}
	store := &SQLiteStore{db: db}
	if err := store.migrate(); err != nil {
		_ = db.Close()
		return nil, err
	}
	return store, nil
}

func (s *SQLiteStore) Close() error {
	if s == nil || s.db == nil {
		return nil
	}
	return s.db.Close()
}

func (s *SQLiteStore) migrate() error {
	statements := []string{
		`CREATE TABLE IF NOT EXISTS registered_clients (
			fingerprint TEXT PRIMARY KEY,
			token TEXT NOT NULL,
			registered_at TEXT NOT NULL
		)`,
		`CREATE TABLE IF NOT EXISTS pending_messages (
			id TEXT PRIMARY KEY,
			sender TEXT NOT NULL,
			recipient TEXT NOT NULL,
			payload TEXT NOT NULL,
			timestamp TEXT NOT NULL,
			state TEXT NOT NULL,
			updated_at TEXT NOT NULL
		)`,
	}
	for _, stmt := range statements {
		if _, err := s.db.Exec(stmt); err != nil {
			return err
		}
	}
	return nil
}

func (s *SQLiteStore) RegisterClient(fingerprint, token string) error {
	_, err := s.db.Exec(`INSERT INTO registered_clients(fingerprint, token, registered_at) VALUES(?, ?, ?) 
		ON CONFLICT(fingerprint) DO UPDATE SET token=excluded.token, registered_at=excluded.registered_at`,
		fingerprint, token, time.Now().UTC().Format(time.RFC3339Nano))
	return err
}

func (s *SQLiteStore) TokenForFingerprint(fingerprint string) (string, error) {
	row := s.db.QueryRow(`SELECT token FROM registered_clients WHERE fingerprint = ?`, fingerprint)
	var token string
	if err := row.Scan(&token); err != nil {
		return "", err
	}
	return token, nil
}

func (s *SQLiteStore) QueueEnvelope(env Envelope) error {
	_, err := s.db.Exec(`INSERT OR REPLACE INTO pending_messages(id, sender, recipient, payload, timestamp, state, updated_at)
		VALUES(?, ?, ?, ?, ?, 'queued', ?)`,
		env.ID, env.Sender, env.Recipient, env.Payload, env.Timestamp.UTC().Format(time.RFC3339Nano), time.Now().UTC().Format(time.RFC3339Nano))
	return err
}

func (s *SQLiteStore) MarkDelivered(id string) error {
	_, err := s.db.Exec(`UPDATE pending_messages SET state='delivered', updated_at=? WHERE id=?`, time.Now().UTC().Format(time.RFC3339Nano), id)
	return err
}

func (s *SQLiteStore) DeleteEnvelope(id string) error {
	_, err := s.db.Exec(`DELETE FROM pending_messages WHERE id=?`, id)
	return err
}

func (s *SQLiteStore) PendingForRecipient(recipient string) ([]Envelope, error) {
	rows, err := s.db.Query(`SELECT id, sender, recipient, payload, timestamp FROM pending_messages WHERE recipient=? AND state='queued' ORDER BY timestamp ASC`, recipient)
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	var result []Envelope
	for rows.Next() {
		var env Envelope
		var ts string
		if err := rows.Scan(&env.ID, &env.Sender, &env.Recipient, &env.Payload, &ts); err != nil {
			return nil, err
		}
		parsed, err := time.Parse(time.RFC3339Nano, ts)
		if err != nil {
			return nil, err
		}
		env.Timestamp = parsed
		result = append(result, env)
	}
	return result, rows.Err()
}

func (s *SQLiteStore) CountQueued() (int, error) {
	row := s.db.QueryRow(`SELECT COUNT(*) FROM pending_messages WHERE state='queued'`)
	var count int
	if err := row.Scan(&count); err != nil {
		return 0, err
	}
	return count, nil
}

func (s *SQLiteStore) CleanupExpired(ttl time.Duration) (int64, error) {
	cutoff := time.Now().UTC().Add(-ttl).Format(time.RFC3339Nano)
	res, err := s.db.Exec(`DELETE FROM pending_messages WHERE timestamp < ?`, cutoff)
	if err != nil {
		return 0, err
	}
	return res.RowsAffected()
}

func (s *SQLiteStore) CountRegistered() (int, error) {
	row := s.db.QueryRow(`SELECT COUNT(*) FROM registered_clients`)
	var count int
	if err := row.Scan(&count); err != nil {
		return 0, err
	}
	return count, nil
}

func (s *SQLiteStore) ErrNotFound() error { return errors.New("not found") }

func wrapErr(prefix string, err error) error {
	if err == nil {
		return nil
	}
	return fmt.Errorf("%s: %w", prefix, err)
}