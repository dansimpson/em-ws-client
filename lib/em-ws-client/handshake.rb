# encoding: UTF-8

module EventMachine::WebSocketCodec

  # Responsbile for generating the request and
  # validating the response
  class Handshake

    class HandshakeError < StandardError; end

    Status = /^HTTP\/1.1 (\d+)/i.freeze
    Header = /^([^:]+):\s*(.+)$/i.freeze

    attr_accessor :extra

    def initialize uri, origin="em-ws-client"
      @uri = uri
      @origin = origin
      @buffer = ""
      @complete = false
      @valid = false
      @extra = ""
    end

    def request
      headers = ["GET #{path} HTTP/1.1"]
      headers << "Connection: keep-alive, Upgrade"
      headers << "Host: #{host}"
      headers << "Sec-WebSocket-Key: #{request_key}"
      headers << "Sec-WebSocket-Version: 13"
      headers << "Origin: #{@origin}"
      headers << "Upgrade: websocket"
      headers << "User-Agent: em-ws-client"
      headers << "\r\n"

      headers.join "\r\n"
    end

    def << data
      @buffer << data

      if @buffer.index "\r\n\r\n"

        response, @extra = @buffer.split("\r\n\r\n", 2)

        lines = response.split "\r\n"

        if Status =~ lines.shift
          if $1.to_i != 101
            raise HandshakeError.new "Received code #{$1}"
          end
        end

        table = {}
        lines.each do |line|
          header = /^([^:]+):\s*(.+)$/.match(line)
          table[header[1].downcase.strip] = header[2].strip if header
        end

        @complete = true
        if table["sec-websocket-accept"] == response_key
          @valid = true
        else
          raise HandshakeError.new "Invalid Sec-Websocket-Accept"
        end
      end
    end

    def complete?
      @complete
    end

    def valid?
      @valid
    end

    def host
      @uri.host + (@uri.port ? ":#{@uri.port}" : "")
    end

    def path
      (@uri.path.empty? ? "/" : @uri.path) + (@uri.query ? "?#{@uri.query}" : "")
    end

    # Build a unique request key to match against
    def request_key
      @request_key ||= SecureRandom::base64
    end

    # Build the response key from the given request key
    # for comparison with the response value.
    def response_key
      Base64.encode64(Digest::SHA1.digest("#{request_key}258EAFA5-E914-47DA-95CA-C5AB0DC85B11")).chomp
    end

  end
end