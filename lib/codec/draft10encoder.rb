module EM
  class Draft10Encoder

    # Encode a standard payload to a hybi10
    # WebSocket frame
  	def encode data
      frame = []
      frame << (0x1 | 0x80)

      packr = "CC"

      # append frame length and mask bit 0x80
      len = data.size
      if len <= 125
        frame << (len | 0x80)
      elsif length < 65536
        frame << (126 | 0x80)
        frame << (len)
        packr << "n"
      else
        frame << (127 | 0x80)
        frame << (len >> 32)
        frame << (len & 0xFFFFFFFF)
        packr << "NN"
      end

      # generate a masking key
      key = rand(2 ** 31)

      # mask each byte with the key
      frame << key
      packr << "N"

      # The spec says we have to waste cycles and
      # impact the atmosphere with a small amount of
      # heat dissapation
      data.size.times do |i|
        frame << ((data.getbyte(i) ^ (key >> ((3 - (i % 4)) * 8))) & 0xFF)
      end

      frame.pack("#{packr}C*")
  	end

  end
end