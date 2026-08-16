package jrmclient

import (
	"context"
	"encoding/json"
	"fmt"
)

// CreatePaste creates a new paste owned by the authenticated caller via
// POST /api/v1/pastes. Requires a bearer token (see SetToken/GetToken).
func (c *Client) CreatePaste(ctx context.Context, content string) (*CreatePasteResponse, error) {
	body, err := json.Marshal(map[string]string{"content": content})
	if err != nil {
		return nil, fmt.Errorf("jrmclient: encoding request: %w", err)
	}

	var out CreatePasteResponse
	if err := c.doRequest(ctx, "POST", "/api/v1/pastes", nil, body, requestOptions{
		contentType: "application/json",
		authorize:   true,
	}, &out); err != nil {
		return nil, err
	}
	return &out, nil
}

// GetPaste retrieves a paste's content by id via GET /api/v1/pastes. This
// endpoint is publicly readable and requires no authentication.
func (c *Client) GetPaste(ctx context.Context, id string) (*Paste, error) {
	var out Paste
	if err := c.doRequest(ctx, "GET", "/api/v1/pastes", map[string]string{"id": id}, nil, requestOptions{}, &out); err != nil {
		return nil, err
	}
	return &out, nil
}

// DeletePaste deletes a paste owned by the authenticated caller via
// DELETE /api/v1/pastes. Requires a bearer token.
func (c *Client) DeletePaste(ctx context.Context, id string) (*StatusResponse, error) {
	var out StatusResponse
	if err := c.doRequest(ctx, "DELETE", "/api/v1/pastes", map[string]string{"id": id}, nil, requestOptions{
		authorize: true,
	}, &out); err != nil {
		return nil, err
	}
	return &out, nil
}

// ListPastes returns the authenticated caller's non-expired pastes, most
// recently created first, via GET /api/v1/user/pastes. Requires a bearer
// token.
func (c *Client) ListPastes(ctx context.Context) ([]PasteSummary, error) {
	var out []PasteSummary
	if err := c.doRequest(ctx, "GET", "/api/v1/user/pastes", nil, nil, requestOptions{
		authorize: true,
	}, &out); err != nil {
		return nil, err
	}
	return out, nil
}
