# jrm-code-client (Python)

Python client bindings for the [JRM Code Project](https://jrm-code-project.com) HTTP API.

## Install

```
pip install -e ./python[test]   # from the repo root, for development
```

## Usage

```python
from jrm_code_client import JrmCodeClient

client = JrmCodeClient()  # defaults to https://jrm-code-project.com

token = client.get_token("alice", "my-api-key")
client.token = token.access_token

created = client.create_paste('(print "hello")')
print("created paste:", created.id)

paste = client.get_paste(created.id)  # public, no auth required
print(paste.content)
```

## Errors

Non-2xx responses raise `jrm_code_client.ApiError`, which carries
`status_code`, `reason`, and `body`:

```python
from jrm_code_client import ApiError

try:
    client.get_paste("missing")
except ApiError as e:
    if e.status_code == 404:
        ...  # handle "not found"
```

Calling a method that requires authentication before `client.token` is set
raises a `RuntimeError` immediately, without making an HTTP request.

## Testing

```
cd python
pip install -e ".[test]"
python -m pytest              # run everything
python -m pytest -k test_ping  # run a single test
```

Tests mock HTTP via the [`responses`](https://github.com/getsentry/responses)
library — no network access or live credentials are required.
