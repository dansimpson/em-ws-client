em-ws-client
------------
RFC 6455 Compliant WebSocket client for ruby.  See report for compliance: [View Autobahn Report][0]

Installation
------------

```bash
$ gem install em-ws-client
```

Sending and Receiving Messages
------------------------------

```ruby
require "em-ws-client"

EM.run do

  # Establish the connection
  ws = EM::WebSocketClient.new("ws://server/path")

  # Simple echo
  # If the binary flag is set, then
  # the message is a string encoded as ASCII_8BIT
  # otherwise it's encoded as UTF-8
  ws.onmessage do |msg, binary|
    conn.send_message msg, binary
  end

  # Send a text message
  ws.send_message "hello!"

  # Send a binary message
  ws.send_message [2,3,4].pack("NnC"), true

end
```

Control Events
--------------

```ruby
require "em-ws-client"

EM.run do

  # Establish the connection
  ws = EM::WebSocketClient.new("ws://server/path")

  ws.onopen do
    # fire away
  end

  ws.onclose do |code, explain|
    # could be good, or not
  end

  ws.onping do |msg|
    # we automatically pong, but this is here
  end

  ws.onerror do |code, message|
    # errors close the connection (per spec), but you can at
    # least learn why with this
  end

  ws.ping "ping"

  ws.onpong do |msg|
    # mes -> what you called ping with
  end

end
```

Streaming API (Design Only)
---------------------------
Thoughts appreciated.

```ruby

# streaming in
ws.onstream do |stream|
  
  # stream started
  # stream.binary?

  stream.ondata do |chunk|
    # ...
  end

  stream.onclose do
    # stream finished
  end
end

# streaming out
ws.stream(true) do |stream|
  100.times do |i|
    stream << [i].pack("N")
  end
  stream.close
end

```

[0]: http://dansimpson.github.com/em-ws-client/autobahn/report.html