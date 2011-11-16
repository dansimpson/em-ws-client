$: << File.dirname(__FILE__) + "/../lib/"

require "em-ws-client"


dec = EM::Draft10Decoder.new
enc = EM::Draft10Encoder.new

puts dec.decode(enc.encode("monkey"))

EM.run do

  conn = EM::WebSocketClient.new("ws://localhost:8080/test")
  puts conn.state
  puts conn.disconnected?

  conn.onopen do
    puts "Opened"

    EM.add_periodic_timer(2) do
      conn.send_data "Ping!"
    end
  end

  conn.onclose do
    puts "Closed"
  end

  conn.onmessage do |msg|
    puts msg
  end

end