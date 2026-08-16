package jrmclient

import (
	"bytes"
	"context"
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"net/url"
	"sync"
	"time"
)

// DefaultBaseURL is the production base URL for the JRM Code Project API.
const DefaultBaseURL = "https://jrm-code-project.com"

// Client is an HTTP client for the JRM Code Project API. The zero value is
// not usable; construct one with NewClient.
//
// Client is safe for concurrent use once constructed. SetToken may be called
// concurrently with requests.
type Client struct {
	baseURL    string
	httpClient *http.Client

	mu    sync.RWMutex
	token string
}

// Option configures a Client constructed by NewClient.
type Option func(*Client)

// WithHTTPClient overrides the http.Client used to make requests. Useful for
// injecting timeouts, transports, or test doubles.
func WithHTTPClient(hc *http.Client) Option {
	return func(c *Client) { c.httpClient = hc }
}

// WithToken sets the bearer token used to authenticate requests that require
// it. Equivalent to calling SetToken after construction.
func WithToken(token string) Option {
	return func(c *Client) { c.token = token }
}

// NewClient creates a Client for the given API base URL (e.g.
// DefaultBaseURL). baseURL should not have a trailing slash.
func NewClient(baseURL string, opts ...Option) *Client {
	c := &Client{
		baseURL:    baseURL,
		httpClient: &http.Client{Timeout: 30 * time.Second},
	}
	for _, opt := range opts {
		opt(c)
	}
	return c
}

// SetToken updates the bearer token attached to subsequent authenticated
// requests. Pass an empty string to clear it.
func (c *Client) SetToken(token string) {
	c.mu.Lock()
	defer c.mu.Unlock()
	c.token = token
}

// Token returns the bearer token currently configured on the client.
func (c *Client) Token() string {
	c.mu.RLock()
	defer c.mu.RUnlock()
	return c.token
}

// APIError represents a non-2xx response from the API.
type APIError struct {
	StatusCode int
	Status     string
	Body       string
}

func (e *APIError) Error() string {
	if e.Body == "" {
		return fmt.Sprintf("jrmclient: %s", e.Status)
	}
	return fmt.Sprintf("jrmclient: %s: %s", e.Status, e.Body)
}

// requestOptions customizes a single request beyond the common cases.
type requestOptions struct {
	contentType string
	authorize   bool
	extraHeader map[string]string
}

// doRequest issues an HTTP request against the API. body, if non-nil, is
// sent as the raw request body (already encoded by the caller). result, if
// non-nil, receives the JSON-decoded response body on success.
func (c *Client) doRequest(ctx context.Context, method, path string, query map[string]string, body []byte, opts requestOptions, result any) error {
	reqURL := c.baseURL + path
	if len(query) > 0 {
		q := url.Values{}
		for k, v := range query {
			q.Set(k, v)
		}
		reqURL += "?" + q.Encode()
	}

	var reqBody io.Reader
	if body != nil {
		reqBody = bytes.NewReader(body)
	}

	req, err := http.NewRequestWithContext(ctx, method, reqURL, reqBody)
	if err != nil {
		return fmt.Errorf("jrmclient: building request: %w", err)
	}

	if opts.contentType != "" {
		req.Header.Set("Content-Type", opts.contentType)
	}
	for k, v := range opts.extraHeader {
		req.Header.Set(k, v)
	}
	if opts.authorize {
		c.mu.RLock()
		tok := c.token
		c.mu.RUnlock()
		if tok == "" {
			return fmt.Errorf("jrmclient: %s %s requires a bearer token; call SetToken or GetToken first", method, path)
		}
		req.Header.Set("Authorization", "Bearer "+tok)
	}

	resp, err := c.httpClient.Do(req)
	if err != nil {
		return fmt.Errorf("jrmclient: performing request: %w", err)
	}
	defer resp.Body.Close()

	respBody, err := io.ReadAll(resp.Body)
	if err != nil {
		return fmt.Errorf("jrmclient: reading response: %w", err)
	}

	if resp.StatusCode < 200 || resp.StatusCode >= 300 {
		return &APIError{StatusCode: resp.StatusCode, Status: resp.Status, Body: string(respBody)}
	}

	if result != nil && len(respBody) > 0 {
		if err := json.Unmarshal(respBody, result); err != nil {
			return fmt.Errorf("jrmclient: decoding response: %w", err)
		}
	}
	return nil
}

// doRequestRaw behaves like doRequest but returns the raw response body as a
// string via out, rather than JSON-decoding it. Used for endpoints whose
// responses are text/plain (e.g. Chef).
func (c *Client) doRequestRaw(ctx context.Context, method, path string, query map[string]string, body []byte, opts requestOptions, out *string) error {
	reqURL := c.baseURL + path
	if len(query) > 0 {
		q := url.Values{}
		for k, v := range query {
			q.Set(k, v)
		}
		reqURL += "?" + q.Encode()
	}

	var reqBody io.Reader
	if body != nil {
		reqBody = bytes.NewReader(body)
	}

	req, err := http.NewRequestWithContext(ctx, method, reqURL, reqBody)
	if err != nil {
		return fmt.Errorf("jrmclient: building request: %w", err)
	}

	if opts.contentType != "" {
		req.Header.Set("Content-Type", opts.contentType)
	}
	for k, v := range opts.extraHeader {
		req.Header.Set(k, v)
	}
	if opts.authorize {
		c.mu.RLock()
		tok := c.token
		c.mu.RUnlock()
		if tok == "" {
			return fmt.Errorf("jrmclient: %s %s requires a bearer token; call SetToken or GetToken first", method, path)
		}
		req.Header.Set("Authorization", "Bearer "+tok)
	}

	resp, err := c.httpClient.Do(req)
	if err != nil {
		return fmt.Errorf("jrmclient: performing request: %w", err)
	}
	defer resp.Body.Close()

	respBody, err := io.ReadAll(resp.Body)
	if err != nil {
		return fmt.Errorf("jrmclient: reading response: %w", err)
	}

	if resp.StatusCode < 200 || resp.StatusCode >= 300 {
		return &APIError{StatusCode: resp.StatusCode, Status: resp.Status, Body: string(respBody)}
	}

	*out = string(respBody)
	return nil
}
