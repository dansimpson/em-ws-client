spec = Gem::Specification.new do |s|
  s.name = "em-websocket-client"
  s.version = "0.1"
  s.date = "2011-09-26"
  s.summary = "EventMachine WebSocket Client"
  s.email = "dan@shove.io"
  s.homepage = "https://github.com/dansimpson/em-websocket-client"
  s.description = "A simple, evented WebSocket client for your ruby projects"
  s.has_rdoc = true
  
  s.add_dependency("eventmachine", ">= 0.12.10")
  s.add_dependency("state_machine", ">= 1.0.0")

  s.authors = ["Dan Simpson"]

  s.files = `git ls-files`.split("\n")
  s.test_files = `git ls-files -- {test,spec,features}/*`.split("\n")

end
