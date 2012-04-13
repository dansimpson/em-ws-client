# EM WebSocket Client
Rfc6455 WebSocket client for ruby.  Almost 100% Spec compliant (see autobahn tests).

# Installing
```bash
$ gem install em-ws-client
```

# Establishing a Connection

```ruby
require "em-ws-client"

EM.run do

  # Establish the connection
  connection = EM::WebSocketClient.new("ws://server/path")

  connection.onopen do
    # Handle open event
  end

  conn.onclose do
    # Handle close event
  end

  # Echo!
  conn.onmessage do |msg, binary|
    if binary
      conn.send_data msg, true
    else
      conn.send_data msg
    end
  end

  conn.onping do |msg|
    # we automatically respond, but if you want...
  end

  conn.onerror do |code, message|
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