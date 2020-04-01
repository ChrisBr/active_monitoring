$:.push File.expand_path("lib", __dir__)

# Maintain your gem's version:
require "active_monitoring/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |spec|
  spec.name        = "active_monitoring"
  spec.version     = ActiveMonitoring::VERSION
  spec.authors     = ["Christian Bruckmayer"]
  spec.email       = ["christian@bruckmayer.net"]
  spec.homepage    = "https://github.com/ChrisBr/active_monitoring"
  spec.summary     = "Summary of ActiveMonitoring."
  spec.description = "Description of ActiveMonitoring."
  spec.license     = "MIT"

  spec.files = Dir["{app,config,db,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.md"]

  spec.add_dependency "rails", "~> 6.0.2", ">= 6.0.2.2"

  spec.add_development_dependency "byebug"
  spec.add_development_dependency "rspec-rails"
  spec.add_development_dependency "rubocop-performance"
  spec.add_development_dependency "rubocop-rails"
  spec.add_development_dependency "sqlite3"
end
