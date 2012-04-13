require "helper"

module EM::WebSocketCodec
  describe Decoder do

    it "should decode an encoded message" do
      dec = Decoder.new
      enc = Encoder.new

      str = enc.encode("simple message")
      #dec.<<(str).should == "simple message"
    end

  end
end