package jrmclient

// TokenResponse is returned by GetToken on success.
type TokenResponse struct {
	AccessToken string `json:"access_token"`
	ExpiresIn   int    `json:"expires_in"`
	TokenType   string `json:"token_type"`
}

// Paste is a single paste's full content, as returned by GetPaste.
type Paste struct {
	ID      string `json:"id"`
	Content string `json:"content"`
}

// PasteSummary is a single entry in the authenticated caller's paste list,
// as returned by ListPastes. It omits the full content in favor of a
// preview.
type PasteSummary struct {
	ID             string  `json:"id"`
	CreatedAt      string  `json:"created_at"`
	ExpiresAt      *string `json:"expires_at"`
	ContentPreview string  `json:"content_preview"`
}

// CreatePasteResponse is returned by CreatePaste on success.
type CreatePasteResponse struct {
	Status string `json:"status"`
	ID     string `json:"id"`
}

// StatusResponse is a generic {"status": "..."} response, e.g. from
// DeletePaste.
type StatusResponse struct {
	Status string `json:"status"`
}

// PingResponse is returned by Ping on success.
type PingResponse struct {
	Status string `json:"status"`
	User   string `json:"user"`
	Tier   string `json:"tier"`
}

// EchoResponse is returned by Echo on success.
type EchoResponse struct {
	Status string `json:"status"`
	Echo   any    `json:"echo"`
}
