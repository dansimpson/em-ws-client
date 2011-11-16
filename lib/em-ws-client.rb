require "rubygems"
require "eventmachine"
require "state_machine"
require "uri"
require "digest/sha1"
require "base64"
require "codec/draft10encoder.rb"
require "codec/draft10decoder.rb"


module EM
  class WebSocketClient
    
    Version = "0.1.1"

    class WebSocketConnection < EM::Connection

      def client=(client)
        @client = client
        @client.connection = self
      end

      def receive_data(data)
        @client.receive_data data
      end

      def unbind(reason=nil)
        @client.disconnect
      end

    end

    attr_accessor :connection

    state_machine :initial => :disconnected do

      # States
      state :disconnected
      state :connecting
      state :negotiating
      state :established
      state :failed

      after_transition :to => :connecting, :do => :connect
      after_transition :to => :negotiating, :do => :on_negotiating
      after_transition :to => :established, :do => :on_established

      event :start do
        transition :disconnected => :connecting
      end

      event :negotiate do
        transition :connecting => :negotiating
      end

      event :complete do
        transition :negotiating => :established
      end

      event :error do
        transition all => :failed
      end

      event :disconnect do
        transition all => :disconnected
      end

    end

    def initialize uri, origin="em-websocket-client"
      super();

      @uri = URI.parse(uri)
      @origin = origin
      @queue = []

      @encoder = Draft10Encoder.new
      @decoder = Draft10Decoder.new
      
      @request_key = build_request_key
      @buffer = ""

      start
    end

    # Called on opening of the websocket
    def onopen &block
      @open_handler = block
    end
    
    # Called on the close of the connection
    def onclose &block
      @cblock = block
    end
    
    # Called when a message is received
    def onmessage &block
      @message_handler = block
    end
    
    # EM callback
    def receive_data(data)
      if negotiating?
        @buffer << data
        request, rest = @buffer.split("\r\n\r\n", 2)
        if rest
          @buffer = ""
          handle_response(request)
          receive_data rest
        end
      else
        message = @decoder.decode(data)
        if message
          if @message_handler
           @message_handler.call(message)
         end
        end
      end
    end

    # Send a WebSocket frame to the remote
    # host.
    def send_data data
      if established?
        connection.send_data(@encoder.encode(data))
      else
        @queue << data
      end
    end

    private

    # Connect to the remote host and synchonize the connection
    # and this client object
    def connect
      EM.connect @uri.host, @uri.port || 80, WebSocketConnection do |conn|
        conn.client = self
        negotiate
      end
    end

    # Send HTTP request with upgrade goodies
    # to the remote host
    def on_negotiating
      request = "GET #{@uri.path} HTTP/1.1\r\n"
      request << "Upgrade: WebSocket\r\n"
      request << "Connection: Upgrade\r\n"
      request << "Host: #{@uri.host}\r\n"
      request << "Sec-WebSocket-Key: #{@request_key}\r\n"
      request << "Sec-WebSocket-Version: 8\r\n"
      request << "Sec-WebSocket-Origin: #{@origin}\r\n"
      request << "\r\n"
      connection.send_data(request)
    end

    def on_established
      if @open_handler
        @open_handler.call
      end
      
      while !@queue.empty?
        send_data @queue.shift
      end
    end

    # Handle the HTTP response and ensure it's valid
    # by checking the Sec-WebSocket-Accept header
    def handle_response response
      lines = response.split("\r\n")
      table = {}

      lines.each do |line|
        header = /^([^:]+):\s*(.+)$/.match(line)
        table[header[1].downcase.strip] = header[2].strip if header
      end

      if table["sec-websocket-accept"] == build_response_key
        complete
      else
        error
      end
    end

    # Build a unique request key to match against
    def build_request_key
      Base64.encode64(Time.now.to_i.to_s(16)).chomp
    end

    # Build the response key from the given request key
    # for comparison with the response value.
    def build_response_key
      Base64.encode64(Digest::SHA1.digest("#{@request_key}258EAFA5-E914-47DA-95CA-C5AB0DC85B11")).chomp
    end
    
  end
end