package server

import (
	"path/filepath"
	"testing"
	"time"
)

func TestSQLiteStoreQueueAndRecipientLookup(t *testing.T) {
	dbPath := filepath.Join(t.TempDir(), "relay.db")
	store, err := NewSQLiteStore(dbPath)
	if err != nil {
		t.Fatal(err)
	}
	defer store.Close()

	if err := store.RegisterClient("fingerprint-a", "token"); err != nil {
		t.Fatal(err)
	}
	if err := store.QueueEnvelope(Envelope{ID: "msg-1", Sender: "fingerprint-a", Recipient: "fingerprint-b", Payload: "cipher", Timestamp: time.Now().UTC()}); err != nil {
		t.Fatal(err)
	}
	msgs, err := store.PendingForRecipient("fingerprint-b")
	if err != nil {
		t.Fatal(err)
	}
	if len(msgs) != 1 || msgs[0].ID != "msg-1" {
		t.Fatalf("unexpected queued messages: %+v", msgs)
	}
}