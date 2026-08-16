package jrmclient

import (
	"context"
	"encoding/json"
	"fmt"
)

// Ping performs a trivial JWT-authenticated liveness check via
// GET /api/v1/ping, returning the caller's identity and tier as decoded
// from the bearer token.
func (c *Client) Ping(ctx context.Context) (*PingResponse, error) {
	var out PingResponse
	if err := c.doRequest(ctx, "GET", "/api/v1/ping", nil, nil, requestOptions{
		authorize: true,
	}, &out); err != nil {
		return nil, err
	}
	return &out, nil
}

// Echo sends an arbitrary JSON-serializable value to POST /api/v1/echo and
// returns it verbatim as decoded by the server, useful for confirming
// request encoding and auth header handling end to end. Requires a bearer
// token.
func (c *Client) Echo(ctx context.Context, payload any) (*EchoResponse, error) {
	body, err := json.Marshal(payload)
	if err != nil {
		return nil, fmt.Errorf("jrmclient: encoding request: %w", err)
	}

	var out EchoResponse
	if err := c.doRequest(ctx, "POST", "/api/v1/echo", nil, body, requestOptions{
		contentType: "application/json",
		authorize:   true,
	}, &out); err != nil {
		return nil, err
	}
	return &out, nil
}
