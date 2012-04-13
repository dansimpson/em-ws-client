# encoding: UTF-8

module EventMachine::WebSocketCodec

  # A WebSocket frame decoder based on
  # RFC 6455
  class Decoder

    include Protocol

    def initialize debug=false
      @fragmented = false
      @buffer = ""
      @chunks = ""
      @debug  = debug

      @callbacks = {}
    end


    def onclose &block; @callbacks[:close] = block; end
    def onping &block; @callbacks[:ping] = block; end
    def onpong &block; @callbacks[:pong] = block; end
    def onframe &block; @callbacks[:frame] = block; end
    def onerror &block; @callbacks[:error] = block; end

    # Decode a WebSocket frame
    # +data+ the frame data
    # returns false if the packet is incomplete
    # and a decoded message otherwise
    def << data

      # put the data into the buffer, as
      # we might be replaying
      if data
        @buffer << data
      end

      # Don't do work if we don't have to
      if @buffer.length < 2
        return
      end

      # decode the first 2 bytes, with
      # opcode, lengthgth, masking bit, and frag bit
      h1, h2 = @buffer.unpack("CC")

      # check the fragmentation bit to see
      # if this is a message fragment
      fin = ((h1 & 0x80) == 0x80)

      # used to keep track of our position in the buffer
      offset = 2

      # see above for possible opcodes
      opcode = (h1 & 0x0F)

      # the leading length idicator
      length = (h2 & 0x7F)

      # masking bit, is the data masked with
      # a specified masking key?
      masked = ((h2 & 0x80) == 0x80)

      # Find errors and fail fast
      if h1 & 0b01110000 != 0
        return emit :error, 1002, "RSV bits must be 0"
      end

      if opcode > 7
        if !fin
          return emit :error, 1002, "Control frame cannot be fragmented"
        elsif length > 125
          return emit :error, 1002, "Control frame is too large #{length}"
        elsif opcode > 0xA
          return emit :error, 1002, "Unexpected reserved opcode #{opcode}"
        elsif opcode == CLOSE && length == 1
          return emit :error, 1002, "Close control frame with payload of length 1"
        end
      else
        if opcode != CONTINUATION && opcode != TEXT_FRAME && opcode != BINARY_FRAME
          return emit :error, 1002, "Unexpected reserved opcode #{opcode}"
        end
      end

      # spare no bytes hybi!
      if length > 125
        if length == 126
          length = @buffer.unpack("@#{offset}n").first
          offset += 2
        else
          length = @buffer.unpack("@#{offset}L!>").first
          offset += 8
        end
      end

      # unpack the masking key
      if masked
        key = @buffer.unpack("@#{offset}N").first
        offset += 4
      end

      # replay on next frame
      if @buffer.size < (length + offset)
        return false
      end

      # Read the important bits
      payload = @buffer.unpack("@#{offset}C#{length}")

      # Unmask the data if it"s masked
      if masked
        payload.size.times do |i|
          payload[i] = ((payload[i] ^ (key >> ((3 - (i % 4)) * 8))) & 0xFF)
        end
      end
      
      # finally, extract the message!
      payload = payload.pack("C*")

      case opcode
      when CONTINUATION

        # We shouldn't get a contination without
        # knowing whether or not it's binary or text
        unless @fragmented
          return emit :error, 1002, "Unexepected continuation"
        end

        # Validate the UTF for fast failing.  This won't catch
        # boundary errors, so we need to do some more work
        if @fragmented == :text
          unless encode(payload).valid_encoding?
            return emit :error, 1007, "Invalid UTF"
          end
        end

        @chunks << payload
        if fin

          # TODO: Boundary validate
          # if @fragmented == :text
          #   unless encode(@chunks).valid_encoding?
          #     return emit :error, 1007, "Invalid UTF"
          #   end
          # end
          emit :frame, @chunks, @fragmented == :binary
          @chunks = nil
          @fragmented = false
        end

      when TEXT_FRAME
        # We shouldn't get a text frame when we
        # are expecting a continuation
        if @fragmented
          return emit :error, 1002, "Unexepected frame"
        end

        # validate the text as UTF
        unless encode(payload).valid_encoding?
          return emit :error, 1007, "Invalid UTF"
        end  

        # emit or buffer
        if fin
          emit :frame, payload, false
        else
          @chunks = payload
          @fragmented = :text
        end

      when BINARY_FRAME
        # We shouldn't get a text frame when we
        # are expecting a continuation
        if @fragmented
          return emit :error, 1002, "Unexepected frame"
        end

        # emit or buffer
        if fin
          emit :frame, payload, true
        else
          @chunks = payload
          @fragmented = :binary
        end

      when CLOSE
        code = payload == nil ? 1000 : payload.unpack("n").first
        if !valid_close_code? code
          code = 1002
        end
        emit :close, code

      when PING
        emit :ping, payload

      when PONG
        emit :pong, payload

      end

      # Remove data we made use of and call back
      # TODO: remove recursion
      @buffer = @buffer[offset + length..-1] || ""
      if not @buffer.empty?
        self << nil
      end

    end

    private

    # trigger event for upstream
    def emit event, *args
      if @callbacks.key?(event)
        @callbacks[event].call(*args)
      end
    end

    # Determine if the close code we received is valid
    # and close if it's not
    def valid_close_code? code
      case code
      when 1000,1001,1002,1003,1007,1008,1009,1010,1011
        true
      when 3000..3999
        true
      when 4000..4999
        true
      else
        false
      end
    end

    # Force the encoding of the data to UTF for strings
    def encode data
      data.force_encoding("UTF-8")
    end

  end

end