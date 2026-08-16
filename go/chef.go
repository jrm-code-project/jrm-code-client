package jrmclient

import (
	"context"
)

// Chef submits Lisp source code (64 lines or fewer) to "The Chef" for a
// roast, via POST /api/v1/chef. Requires a bearer token (paid tier) and the
// caller's own Google Gemini API key, sent as the x-goog-api-key header.
// The response body is the roast as plain text.
func (c *Client) Chef(ctx context.Context, lispCode, geminiAPIKey string) (string, error) {
	var out string
	err := c.doRequestRaw(ctx, "POST", "/api/v1/chef", nil, []byte(lispCode), requestOptions{
		contentType: "text/plain",
		authorize:   true,
		extraHeader: map[string]string{"x-goog-api-key": geminiAPIKey},
	}, &out)
	if err != nil {
		return "", err
	}
	return out, nil
}
