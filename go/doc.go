// Package jrmclient provides a Go client for the JRM Code Project HTTP API
// (https://jrm-code-project.com), as described by its OpenAPI 3.0.3
// specification (see ../openapi.json at the repository root).
//
// Most endpoints require a bearer JWT. Obtain one with GetToken and either
// pass it explicitly to subsequent calls or use SetToken/WithToken so the
// Client attaches it automatically.
//
// Example:
//
//	c := jrmclient.NewClient("https://jrm-code-project.com")
//	tok, err := c.GetToken(ctx, "alice", "my-api-key")
//	if err != nil {
//		log.Fatal(err)
//	}
//	c.SetToken(tok.AccessToken)
//
//	resp, err := c.CreatePaste(ctx, "(print \"hello\")")
package jrmclient
