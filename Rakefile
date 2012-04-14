require "rspec/core/rake_task"

require "rake/extensiontask"

Rake::ExtensionTask.new("utf8validator")

RSpec::Core::RakeTask.new(:spec)

task :default => :spec