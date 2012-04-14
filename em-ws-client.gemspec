$:.unshift File.dirname(__FILE__) + "/lib"

require "em-ws-client"

spec = Gem::Specification.new do |s|
  s.name = "em-ws-client"
  s.version = EM::WebSocketClient::Version
  s.date = "2012-04-14"
  s.summary = "EventMachine WebSocket Client"
  s.email = "dan@shove.io"
  s.homepage = "https://github.com/dansimpson/em-ws-client"
  s.description = "A simple, fun, evented WebSocket client for your ruby projects"
  s.has_rdoc = true
  
  s.add_dependency("eventmachine", "~> 1.0.0.beta.4")

  s.authors = ["Dan Simpson"]

  s.files = `git ls-files`.split("\n")
  s.test_files = `git ls-files -- {test,spec,features}/*`.split("\n")

end
