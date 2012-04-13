require "rubygems"
require "eventmachine"
require "uri"
require "digest/sha1"
require "base64"
require "iconv"

module EventMachine
  module WebSocketCodec
  end
end

require "em-ws-client/handshake.rb"
require "em-ws-client/protocol.rb"
require "em-ws-client/encoder.rb"
require "em-ws-client/decoder.rb"
require "em-ws-client/client.rb"
