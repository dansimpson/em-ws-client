# EM WebSocket Client
Mimics the browser client implementation to some degree.  Currently implements hixie draft 10.

# Installing
```bash
$ gem install em-ws-client
```

# Establishing a Connection

```ruby
EM.run do

  # Establish the connection
  connection = EM::WebSocketClient.new("ws://server/path")

  connection.onopen do
    # Handle open event
  end

  conn.onclose do
    # Handle close event
  end

end
```

# Sending Data
Send data as a string.  It can be JSON, CSV, etc.  As long
as you can serialize it.

```ruby
connection.send_data "message"

# JSON
connection.send_data {
  :category => "fun",
  :message => "times"
}.to_json
```