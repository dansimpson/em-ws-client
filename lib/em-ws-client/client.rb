# encoding: UTF-8

module EventMachine

  # Public: A fully functional WebSocket client
  # implementation.
  #
  # Examples
  #
  #   ws = WebSocketClient.new "ws://localhost/chat"
  #
  #   ws.onmessage do |msg|
  #     puts msg
  #   end
  #
  #   ws.onopen do
  #     ws.send_message "Hello!"
  #   end
  class WebSocketClient
    
    Version = "0.2.0"
    
    class WebSocketError < StandardError; end

    # Internal: Wrapper
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

    attr_accessor :socket

    # Public: Initialize a WebSocket client
    #
    # uri - The endpoint host url
    # origin - The origin you wish to claim
    #
    # Examples
    #
    #   WebSocketClient.new "ws://localhost:9000/chat"
    #   WebSocketClient.new "ws://ws.site.com/chat", "http://www.site.com/chat"
    #
    # Returns the client
    def initialize uri, origin="em-ws-client"
      super();

      @uri     = URI.parse(uri)
      @origin  = origin
      @buffer  = ""
      
      @encoder = WebSocketCodec::Encoder.new
      @decoder = WebSocketCodec::Decoder.new
      @handshake = WebSocketCodec::Handshake.new @uri, @origin
      
      @callbacks = {}
      @closing = false

      connect
    end

    # Public: Close the connection
    #
    # Examples
    #
    #   ws.unbind
    #   # => ?
    #
    # Returns
    def unbind
      emit :close
    end

    # Bind a callback to the open event
    #
    # block - A block which is called when
    # the connection to the remote host is established
    #
    # Examples
    #
    #   ws.onopen do
    #   end
    #
    # Returns nothing
    def onopen &block
      @callbacks[:open] = block
    end
    
    # Bind a callback to the close event
    #
    # block - A block which is called when
    # the connection to the remote host is closed.
    # Your block receives 2 arguments, with the second
    # potentially being nil.
    #
    # Examples
    #
    #   ws.onclose do |code, explain|
    #   end
    #
    # Returns nothing
    def onclose &block
      @callbacks[:close] = block
    end
    
    # Bind a callback to the message event
    #
    # block - A block which is called when a
    # message is received. The first argument
    # for the block is the message, and the second
    # argument is a binary flag.
    #
    # Examples
    #
    #   ws.onmessage do |message, binary|
    #   end
    #
    # Returns nothing
    def onmessage &block
      @callbacks[:frame] = block
    end
    
    # Bind a callback to the error event
    #
    # block - A block which is called when
    # an error occurs.  The connection is dropped
    # immediately per spec.  The first argument is
    # the close code, and the second is the error.
    #
    # Examples
    #
    #   ws.onerror do |close_code, error|
    #   end
    #
    # Returns nothing
    def onerror &block
      @callbacks[:error] = block
    end

    # Bind a callback to the ping event
    #
    # block - A block which is called when
    # the remote host sends a ping.  A single
    # argument is sent, which contains the ping
    # data sent from the remote host.  A pong
    # is automatically sent.
    #
    # Examples
    #
    #   ws.onping do |data|
    #   end
    #
    # Returns nothing
    def onping &block
      @callbacks[:ping] = block
    end
    
    # Bind a callback to the pong event
    #
    # block - A block which is called when
    # the remote host sends a pong in response
    # to your ping.  It's possible to get unwarrented
    # pongs.
    #
    # Examples
    #
    #   ws.onpong do |data|
    #   end
    #
    # Returns nothing
    def onpong &block
      @callbacks[:pong] = block
    end

    # Internal: called by eventmachine when data is
    # received
    def receive_data(data)
      if @handshake.complete?
        receive_message_data data
      else
        receive_handshake_data data
      end
    end


    # Send a message to the remote host
    #
    # data - The string contents of your message
    #
    # Examples
    #
    #   ws.onping do |data|
    #   end
    #
    # Returns nothing
    def send_message data, binary=false
      if established?
        unless @closing
          @socket.send_data(@encoder.encode(data.to_s, binary ? BINARY_FRAME : TEXT_FRAME))
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

    # Internal: is the handshake complete and valid?
    def established?
      @handshake.complete? && @handshake.valid?
    end

    # Internal: process ws data
    def receive_message_data data
      @decoder << data
    end

    # Internal: process handshake data
    def receive_handshake_data data
      @handshake << data
      if @handshake.complete?
        if @handshake.valid?
          on_handshake_complete
        else
          emit :error, 1, "Handshake failed!"
          @socket.unbind
        end
      end
    end

    # Internal: setup encoder/decoder and bind
    # to all decoder events.
    def on_handshake_complete

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

      if @handshake.extra
       receive_message_data @handshake.extra
      end
    end

    # Internal: Connect to the remote host and synchonize the socket
    # and this client object
    def connect
      EM.connect @uri.host, @uri.port || 80, WebSocketConnection do |conn|
        conn.client = self
        conn.send_data(@handshake.request)
      end
    end

    # Internal: Emit an event
    def emit event, *args
      if @callbacks.key?(event)
        @callbacks[event].call(*args)
      end
    end

  end
end