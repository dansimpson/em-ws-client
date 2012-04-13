require "helper"

module EM::WebSocketCodec
  describe Handshake do

    def craft_response status, message, headers
      response = ["HTTP/1.1 #{status} #{message}"]
      headers.each do |key, val|
        response << "#{key}: #{val}"
      end
      response << "\r\n"
      response.join "\r\n"
    end

    it "should generate a request a 24 byte key" do
      handshake = Handshake.new URI.parse("ws://test.com/test"), "em-test"
      handshake.request_key.length.should == 24
    end

    it "should craft an HTTP request" do
      handshake = Handshake.new URI.parse("ws://test.com/test"), "em-test"
      handshake.request.length.should > 0
    end

    it "should handle an good response" do
      handshake = Handshake.new URI.parse("ws://test.com/test"), "em-test"

      handshake << craft_response(101, "Switching Protocol", {
        "Upgrade" => "WebSocket",
        "Connection" => "Upgrade",
        "Sec-WebSocket-Accept" => handshake.response_key
      })

      handshake.complete?.should be_true
      handshake.valid?.should be_true
      handshake.extra.should be_empty
    end

    it "should handle an bad response" do
      handshake = Handshake.new URI.parse("ws://test.com/test"), "em-test"

      exception = false
      begin
        handshake << craft_response(200, "OK", {
          "Upgrade" => "WebSocket",
          "Connection" => "Upgrade",
          "Sec-WebSocket-Accept" => handshake.response_key
        })
      rescue Handshake::HandshakeError => err
        exception = true
      end

      handshake.complete?.should be_false
      exception.should be_true
    end

    it "should handle an chunked response" do
      handshake = Handshake.new URI.parse("ws://test.com/test"), "em-test"

      response = craft_response(101, "Switching Protocol", {
        "Upgrade" => "WebSocket",
        "Connection" => "Upgrade",
        "Sec-WebSocket-Accept" => handshake.response_key
      })

      response[0..-2].each_byte do |byte|
        handshake << byte
        handshake.complete?.should be_false
      end

      handshake << response[-1..-1]

      handshake.complete?.should be_true
      handshake.valid?.should be_true
      handshake.extra.should be_empty
    end

    it "should handle an response with framing after it" do
      handshake = Handshake.new URI.parse("ws://test.com/test"), "em-test"

      response = craft_response(101, "Switching Protocol", {
        "Upgrade" => "WebSocket",
        "Connection" => "Upgrade",
        "Sec-WebSocket-Accept" => handshake.response_key
      })

      response  << "extradata"
      handshake << response

      handshake.complete?.should be_true
      handshake.valid?.should be_true
      handshake.extra.should == "extradata"
    end

  end
end