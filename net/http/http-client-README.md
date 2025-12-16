# HttpClient

HTTP client library for WSH JScript with support for synchronous/asynchronous requests, JSON, forms, and streaming responses.

## Basic Usage

### Synchronous Requests

```livescript
{ create-http-client } = dependency 'web.HttpClient'

client = create-http-client!

# GET request
response = client.get 'https://api.example.com/data'
if response.ok
  console.log response.content

# POST with content
response = client.post 'https://api.example.com/items', 'raw data', { content-type: 'text/plain' }

# Query parameters
response = client.get 'https://api.example.com/search', { query: { q: 'test', limit: 10 } }

# Form submission
response = client.form 'https://api.example.com/login', { username: 'user', password: 'pass' }
```

### Asynchronous Requests

```livescript
client.get 'https://api.example.com/data', do
  async: yes
  on-ready-state-change: (http) ->
    if http.ready-state is 4
      console.log http.response-text
```

## JSON Client

```livescript
{ create-json-http-client } = dependency 'web.HttpClient'

client = create-json-http-client!

# GET with automatic JSON parsing
response = client.get 'https://api.example.com/users'
if response.ok
  users = response.json
  console.log users

# POST with automatic JSON serialization
response = client.post 'https://api.example.com/users', { name: 'John', email: 'john@example.com' }
console.log response.json
```

## Streaming / SSE

For Server-Sent Events or streaming responses, use the `on-chunk` callback:

```livescript
{ create-http-client } = dependency 'web.HttpClient'

client = create-http-client!

client.get 'https://api.example.com/stream', do
  async: yes
  on-chunk: (chunk, http) ->
    # Process each chunk as it arrives (readyState 3)
    console.log "Received chunk: #chunk"
  on-ready-state-change: (http) ->
    if http.ready-state is 4
      console.log "Stream complete"
```

## Ollama Streaming Example

```livescript
{ create-json-http-client } = dependency 'web.HttpClient'

client = create-json-http-client!

buffer = ''

client.post 'http://localhost:11434/api/generate', 
  do
    model: 'llama2'
    prompt: 'Why is the sky blue?'
  do
    async: yes
    on-chunk: (chunk, http) ->
      buffer += chunk
      
      # Process line-delimited JSON
      lines = buffer.split '\n'
      buffer := lines.pop! # Keep incomplete line in buffer
      
      for line in lines when line.length > 0
        try
          data = eval "(#line)"
          process.stdout.write data.response if data.response
        catch e
          console.error "Parse error: #{e.message}"
    
    on-ready-state-change: (http) ->
      if http.ready-state is 4
        console.log "\nDone"
```

## OpenAI Streaming Example

```livescript
{ create-json-http-client } = dependency 'web.HttpClient'

client = create-json-http-client!

buffer = ''

client.post 'https://api.openai.com/v1/chat/completions',
  do
    model: 'gpt-3.5-turbo'
    messages: [{ role: 'user', content: 'Hello!' }]
    stream: yes
  do
    async: yes
    headers: { 'Authorization': 'Bearer YOUR_API_KEY' }
    on-chunk: (chunk, http) ->
      buffer += chunk
      
      lines = buffer.split '\n'
      buffer := lines.pop!
      
      for line in lines when line.starts-with 'data: '
        data-str = line.substring 6
        continue if data-str is '[DONE]'
        
        try
          data = eval "(#data-str)"
          delta = data.choices.0.delta.content
          process.stdout.write delta if delta
        catch e
          console.error "Parse error: #{e.message}"
    
    on-ready-state-change: (http) ->
      if http.ready-state is 4
        console.log "\nComplete"
```

## Embeddings Example

```livescript
{ create-json-http-client } = dependency 'web.HttpClient'

client = create-json-http-client!

# OpenAI embeddings
response = client.post 'https://api.openai.com/v1/embeddings',
  do
    model: 'text-embedding-ada-002'
    input: 'The quick brown fox jumps over the lazy dog'
  do
    headers: { 'Authorization': 'Bearer YOUR_API_KEY' }

if response.ok
  embedding = response.json.data.0.embedding
  console.log "Embedding dimensions: #{embedding.length}"
  console.log "First 5 values: #{embedding.slice(0, 5).join(', ')}"

# Ollama embeddings
response = client.post 'http://localhost:11434/api/embeddings',
  do
    model: 'nomic-embed-text'
    prompt: 'The quick brown fox jumps over the lazy dog'

if response.ok
  embedding = response.json.embedding
  console.log "Embedding dimensions: #{embedding.length}"
```

## Non-Streaming Inference Example

```livescript
{ create-json-http-client } = dependency 'web.HttpClient'

client = create-json-http-client!

# OpenAI completion (non-streaming)
response = client.post 'https://api.openai.com/v1/chat/completions',
  do
    model: 'gpt-3.5-turbo'
    messages: [
      { role: 'system', content: 'You are a helpful assistant.' }
      { role: 'user', content: 'Explain quantum computing in simple terms.' }
    ]
    max_tokens: 150
    temperature: 0.7
  do
    headers: { 'Authorization': 'Bearer YOUR_API_KEY' }

if response.ok
  message = response.json.choices.0.message.content
  console.log "Response: #{message}"
  console.log "Tokens used: #{response.json.usage.total_tokens}"

# Ollama completion (non-streaming)
response = client.post 'http://localhost:11434/api/generate',
  do
    model: 'llama2'
    prompt: 'Explain quantum computing in simple terms.'
    stream: no

if response.ok
  console.log "Response: #{response.json.response}"
  console.log "Context length: #{response.json.context.length}"
```

## API Reference

### create-http-client()

Returns an HTTP client instance with methods:

- `get(url, options)` - GET request
- `post(url, content, options)` - POST request
- `put(url, content, options)` - PUT request
- `patch(url, content, options)` - PATCH request
- `delete(url, options)` - DELETE request
- `head(url, options)` - HEAD request
- `form(url, data, options, method='POST')` - Form submission

### create-json-http-client()

Returns a JSON HTTP client with automatic serialization/parsing:

- `get(url, options)` - GET with JSON response
- `post(url, data, options)` - POST with JSON request/response
- `put(url, data, options)` - PUT with JSON request/response
- `patch(url, data, options)` - PATCH with JSON request/response
- `delete(url, options)` - DELETE with JSON response

### Options

- `query` - Object of query parameters
- `headers` - Object of HTTP headers
- `content-type` - Content-Type header value
- `content` - Request body content
- `timeout` - Request timeout in milliseconds
- `async` - Boolean for async mode (default: false)
- `on-ready-state-change` - Callback for readyState changes (required for async)
- `on-chunk` - Callback for streaming chunks (readyState 3)

### Response Object

- `ok` - Boolean indicating success (status 200-299)
- `status` - HTTP status code
- `content` - Response body text
- `json` - Parsed JSON (JSON client only)
- `get-header(name)` - Get response header
- `get-all-headers()` - Get all response headers

## Utilities

### encode-key-value-pairs(data)

Encodes an object into URL-encoded key-value pairs:

```livescript
{ encode-key-value-pairs } = dependency 'web.HttpClient'

encoded = encode-key-value-pairs { name: 'John Doe', age: 30 }
# Returns: "name=John%20Doe&age=30"
```
