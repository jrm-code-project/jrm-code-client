package jrmclient

import (
	"context"
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"testing"
)

func TestGetToken(t *testing.T) {
	srv := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		if r.Method != http.MethodPost || r.URL.Path != "/api/v1/auth/token" {
			t.Fatalf("unexpected request: %s %s", r.Method, r.URL.Path)
		}
		if ct := r.Header.Get("Content-Type"); ct != "application/json" {
			t.Fatalf("unexpected Content-Type: %s", ct)
		}
		var body map[string]string
		if err := json.NewDecoder(r.Body).Decode(&body); err != nil {
			t.Fatalf("decoding body: %v", err)
		}
		if body["username"] != "alice" || body["api_key"] != "secret" {
			t.Fatalf("unexpected body: %v", body)
		}
		w.Header().Set("Content-Type", "application/json")
		json.NewEncoder(w).Encode(TokenResponse{AccessToken: "tok", ExpiresIn: 3600, TokenType: "bearer"})
	}))
	defer srv.Close()

	c := NewClient(srv.URL)
	tok, err := c.GetToken(context.Background(), "alice", "secret")
	if err != nil {
		t.Fatalf("GetToken: %v", err)
	}
	if tok.AccessToken != "tok" {
		t.Fatalf("unexpected token: %+v", tok)
	}
}

func TestCreatePasteRequiresToken(t *testing.T) {
	c := NewClient(DefaultBaseURL)
	if _, err := c.CreatePaste(context.Background(), "hello"); err == nil {
		t.Fatal("expected error when no token is set")
	}
}

func TestCreatePasteSendsBearerToken(t *testing.T) {
	srv := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		if got := r.Header.Get("Authorization"); got != "Bearer tok" {
			t.Fatalf("unexpected Authorization header: %s", got)
		}
		w.WriteHeader(http.StatusCreated)
		w.Header().Set("Content-Type", "application/json")
		json.NewEncoder(w).Encode(CreatePasteResponse{Status: "ok", ID: "abc123"})
	}))
	defer srv.Close()

	c := NewClient(srv.URL, WithToken("tok"))
	resp, err := c.CreatePaste(context.Background(), "(print 1)")
	if err != nil {
		t.Fatalf("CreatePaste: %v", err)
	}
	if resp.ID != "abc123" {
		t.Fatalf("unexpected response: %+v", resp)
	}
}

func TestGetPasteNoAuthRequired(t *testing.T) {
	srv := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		if r.URL.Query().Get("id") != "abc123" {
			t.Fatalf("unexpected query: %s", r.URL.RawQuery)
		}
		w.Header().Set("Content-Type", "application/json")
		json.NewEncoder(w).Encode(Paste{ID: "abc123", Content: "hi"})
	}))
	defer srv.Close()

	c := NewClient(srv.URL)
	paste, err := c.GetPaste(context.Background(), "abc123")
	if err != nil {
		t.Fatalf("GetPaste: %v", err)
	}
	if paste.Content != "hi" {
		t.Fatalf("unexpected paste: %+v", paste)
	}
}

func TestAPIErrorOnNon2xx(t *testing.T) {
	srv := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		w.WriteHeader(http.StatusNotFound)
		w.Write([]byte("paste not found"))
	}))
	defer srv.Close()

	c := NewClient(srv.URL)
	_, err := c.GetPaste(context.Background(), "missing")
	if err == nil {
		t.Fatal("expected error")
	}
	apiErr, ok := err.(*APIError)
	if !ok {
		t.Fatalf("expected *APIError, got %T: %v", err, err)
	}
	if apiErr.StatusCode != http.StatusNotFound {
		t.Fatalf("unexpected status code: %d", apiErr.StatusCode)
	}
}

func TestChefSendsGeminiHeaderAndPlainText(t *testing.T) {
	srv := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		if got := r.Header.Get("x-goog-api-key"); got != "gemini-key" {
			t.Fatalf("unexpected gemini key header: %s", got)
		}
		if ct := r.Header.Get("Content-Type"); ct != "text/plain" {
			t.Fatalf("unexpected Content-Type: %s", ct)
		}
		body := make([]byte, r.ContentLength)
		r.Body.Read(body)
		if string(body) != "(print 1)" {
			t.Fatalf("unexpected body: %s", body)
		}
		w.Write([]byte("This code is an abomination."))
	}))
	defer srv.Close()

	c := NewClient(srv.URL, WithToken("tok"))
	roast, err := c.Chef(context.Background(), "(print 1)", "gemini-key")
	if err != nil {
		t.Fatalf("Chef: %v", err)
	}
	if roast != "This code is an abomination." {
		t.Fatalf("unexpected roast: %s", roast)
	}
}

func TestPing(t *testing.T) {
	srv := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		w.Header().Set("Content-Type", "application/json")
		json.NewEncoder(w).Encode(PingResponse{Status: "ok", User: "alice", Tier: "paid"})
	}))
	defer srv.Close()

	c := NewClient(srv.URL, WithToken("tok"))
	resp, err := c.Ping(context.Background())
	if err != nil {
		t.Fatalf("Ping: %v", err)
	}
	if resp.User != "alice" {
		t.Fatalf("unexpected response: %+v", resp)
	}
}
