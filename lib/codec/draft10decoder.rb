module EM

  # A replaying decoder for the IETF Hybi
  # WebSocket protocol specification
  class Draft10Decoder

    CONTINUATION  = 0x0
    TEXT_FRAME    = 0x1
    BINARY_FRAME  = 0x2
    CLOSE         = 0x8
    PING          = 0x9
    PONG          = 0xA

    def initialize
      @buffer = ""
      @chunks = ""
    end

    # Decode a WebSocket frame
    # +data+ the frame data
    # returns false if the packet is incomplete
    # and a decoded message otherwise
    def decode data

      # broken frame
      if data && data.length < 2
        return false
      end

      # put the data into the buffer, as
      # we might be replaying
      @buffer << data

      # decode the first 2 bytes, with
      # opcode, lengthgth, masking bit, and frag bit
      h1, h2 = @buffer.unpack("CC")

      # check the fragmentation bit to see
      # if this is a message fragment
      @chunked = ((h1 & 0x80) != 0x80)

      # used to keep track of our position
      offset = 2

      # see above for possible opcodes
      opcode = (h1 & 0x0F)

      # the leading length idicator
      length = (h2 & 0x7F)

      # masking bit, is the data masked with
      # a specified masking key?
      masked = ((h2 & 0x80) == 0x80)

      # spare no bytes hybi!
      if length > 125
        if length == 126
          length = @buffer.unpack("@#{offset}n").first
          offset += 2
        else
          length1, length2 = @buffer.unpack("@#{offset}NN")
          # TODO.. bigint?
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
      payload = @buffer.unpack("@#{offset}C*")

      # Unmask the data if it's masked
      if masked
        payload.size.times do |i|
          payload[i] = ((payload[i] ^ (key >> ((3 - (i % 4)) * 8))) & 0xFF)
        end
      end
      
      # finally, extract the message!
      payload = payload.pack("C*")

      case opcode
      when CONTINUATION
        @chunks << payload
        unless @chunked
          result = @chunks
          @chunks = ""
          return result
        end
        false
      when TEXT_FRAME
        unless @chunked
          @buffer = ""
          #@buffer.slice!(offset + length, -1)
          return payload
        end
        false
      when BINARY_FRAME
        false #TODO
      when CLOSE
        false #TODO
      when PING
        false #TODO
      when PONG
        false #TODO
      else
        false
      end
    end


  end
end