# encoding: UTF-8

module EventMachine

  class WebSocketClient
    
    Version = "0.2.0"
    
    class WebSocketError < StandardError; end

    class WebSocketConnection < EM::Connection

      def client=(client)
        @client = client
        @client.socket = self
      end

      def receive_data(data)
        @client.receive_data data
      end

      def unbind(reason=nil)
        @client.unbind
      end

    end

    include WebSocketCodec::Protocol

    attr_accessor :socket, :handshake

    def initialize uri, origin="em-ws-client"
      super();

      @uri     = URI.parse(uri)
      @origin  = origin
      @buffer  = ""

      @handshake = WebSocketCodec::Handshake.new @uri, @origin
      
      @callbacks = {}
      @closing = false

      connect
    end

    def unbind
      emit :close
    end

    # Called on opening of the websocket
    def onopen &block
      @callbacks[:open] = block
    end
    
    # Called on the close of the socket
    def onclose &block
      @callbacks[:close] = block
    end
    
    # Called when a message is received
    def onmessage &block
      @callbacks[:frame] = block
    end
    
    def onerror &block
      @callbacks[:error] = block
    end

    def onping &block
      @callbacks[:ping] = block
    end
    
    def onpong &block
      @callbacks[:pong] = block
    end

    # EM callback
    def receive_data(data)
      if handshake.complete?
        receive_message_data data
      else
        receive_handshake_data data
      end
    end


    # Send a WebSocket frame to the remote
    # host.
    def send_data data, binary=false
      if established?
        unless @closing
          socket.send_data(@encoder.encode(data, binary ? BINARY_FRAME : TEXT_FRAME))
        end
      else
        raise WebSocketError.new "can't send on a closed channel"
      end
    end

    def close code=1000, msg=nil
      @closing = true
      @socket.send_data @encoder.close(code, msg)
      @socket.close_connection_after_writing
    end

    private

    def established?
      handshake.complete? && handshake.valid?
    end

    def receive_message_data data
      @decoder << data
    end

    def receive_handshake_data data
      handshake << data
      if handshake.complete?
        if handshake.valid?
          on_handshake_complete
        else
          socket.unbind
        end
      end
    end

    def on_handshake_complete
      @encoder = WebSocketCodec::Encoder.new
      @decoder = WebSocketCodec::Decoder.new

      @decoder.onping do |data|
        @socket.send_data @encoder.pong(data)
        emit :ping, data
      end

      @decoder.onpong do |data|
        emit :pong, data
      end

      @decoder.onclose do |code|
        close code
      end

      @decoder.onframe do |frame, binary|
        emit :frame, frame, binary
      end

      @decoder.onerror do |code, message|
        close code, message
        emit :error, code, message
      end

      emit :open

      if handshake.extra
       receive_message_data handshake.extra
      end
    end

    # Connect to the remote host and synchonize the socket
    # and this client object
    def connect
      EM.connect @uri.host, @uri.port || 80, WebSocketConnection do |conn|
        conn.client = self
        conn.send_data(handshake.request)
      end
    end

    def emit event, *args
      if @callbacks.key?(event)
        @callbacks[event].call(*args)
      end
    end

  end
end