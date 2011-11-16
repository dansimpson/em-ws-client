spec = Gem::Specification.new do |s|
  s.name = "em-ws-client"
  s.version = "0.1.1"
  s.date = "2011-09-26"
  s.summary = "EventMachine WebSocket Client"
  s.email = "dan@shove.io"
  s.homepage = "https://github.com/dansimpson/em-ws-client"
  s.description = "A simple, fun, evented WebSocket client for your ruby projects"
  s.has_rdoc = true
  
  s.add_dependency("eventmachine", "~> 1.0.0.beta.3")
  s.add_dependency("state_machine", "~> 1.0.2")

  s.authors = ["Dan Simpson"]

  s.files = `git ls-files`.split("\n")
  s.test_files = `git ls-files -- {test,spec,features}/*`.split("\n")

end
