package jrmclient

import (
	"context"
	"encoding/json"
	"fmt"
)

// GetToken exchanges a username and API key for a short-lived JWT via
// POST /api/v1/auth/token. This endpoint does not require prior
// authentication. The returned token is not automatically stored on the
// Client; call c.SetToken(resp.AccessToken) to do so.
func (c *Client) GetToken(ctx context.Context, username, apiKey string) (*TokenResponse, error) {
	body, err := json.Marshal(map[string]string{
		"username": username,
		"api_key":  apiKey,
	})
	if err != nil {
		return nil, fmt.Errorf("jrmclient: encoding request: %w", err)
	}

	var out TokenResponse
	if err := c.doRequest(ctx, "POST", "/api/v1/auth/token", nil, body, requestOptions{
		contentType: "application/json",
	}, &out); err != nil {
		return nil, err
	}
	return &out, nil
}
