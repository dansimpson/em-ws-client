# encoding: UTF-8

module EventMachine::WebSocketCodec
    
  class Encoder

    include Protocol

    # Encode a standard payload to a hybi10
    # WebSocket frame
    def encode data, opcode=TEXT_FRAME
      frame = []
      frame << (opcode | 0x80)

      packr = "CC"

      # append frame length and mask bit 0x80
      len = data ? data.size : 0
      if len <= 125
        frame << (len | 0x80)
      elsif len < 65536
        frame << (126 | 0x80)
        frame << len
        packr << "n"
      else
        frame << (127 | 0x80)
        frame << len
        packr << "L!>"
      end

      # generate a masking key
      key = rand(2 ** 31)

      # mask each byte with the key
      frame << key
      packr << "N"

      #puts "op #{opcode} len #{len} bytes #{data}"
      # Apply the masking key to every byte
      len.times do |i|
        frame << ((data.getbyte(i) ^ (key >> ((3 - (i % 4)) * 8))) & 0xFF)
      end

      frame.pack("#{packr}C*")
    end

    # create a close payload with code
    def close code, message
      encode [code ? code : 1000, message].pack("nA*"), CLOSE
    end

    # create a ping payload
    def ping data=nil
      encode data, PING
    end

    # create a pong payload
    def pong data=nil
      encode data, PONG
    end

  end

end