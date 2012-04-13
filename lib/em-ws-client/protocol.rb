module EventMachine
  module WebSocketCodec
    module Protocol
      CONTINUATION  = 0x0
      TEXT_FRAME    = 0x1
      BINARY_FRAME  = 0x2
      CLOSE         = 0x8
      PING          = 0x9
      PONG          = 0xA
    end
  end
end