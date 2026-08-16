# jrmclient

Go client bindings for the [JRM Code Project](https://jrm-code-project.com) HTTP API.

## Install

```
go get github.com/jrm-code-project/jrm-code-client/go
```

## Usage

```go
package main

import (
	"context"
	"fmt"
	"log"

	"github.com/jrm-code-project/jrm-code-client/go"
)

func main() {
	ctx := context.Background()
	c := jrmclient.NewClient(jrmclient.DefaultBaseURL)

	tok, err := c.GetToken(ctx, "alice", "my-api-key")
	if err != nil {
		log.Fatal(err)
	}
	c.SetToken(tok.AccessToken)

	resp, err := c.CreatePaste(ctx, "(print \"hello\")")
	if err != nil {
		log.Fatal(err)
	}
	fmt.Println("created paste:", resp.ID)

	paste, err := c.GetPaste(ctx, resp.ID) // public, no auth required
	if err != nil {
		log.Fatal(err)
	}
	fmt.Println(paste.Content)
}
```

## Errors

Non-2xx responses are returned as `*jrmclient.APIError`, which carries the
HTTP status code and response body:

```go
if _, err := c.GetPaste(ctx, "missing"); err != nil {
	var apiErr *jrmclient.APIError
	if errors.As(err, &apiErr) && apiErr.StatusCode == http.StatusNotFound {
		// handle "not found"
	}
}
```

## Testing

```
go test ./...
```
