$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "hybridge/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "hybridge"
  s.version     = Hybridge::VERSION
  s.authors     = ["Leroy Vallejo", "Sean Watkins"]
  s.email       = ["llvallejo@uh.edu", "slwatkins@uh.edu"]
  s.homepage    = "https://github.com/Bridge2Hyku/HyBridge"
  s.summary     = "This is the gemspec for the HyBridge tool."
  s.description = "This gem will be installed into the Samvera Hyku application"
  s.license     = "Apache 2.0"

  s.files = Dir["{app,config,db,lib}/**/*", "LICENSE.txt", "Rakefile", "README.md"]

  s.add_dependency "rails", ">= 5.1.6"
  s.add_dependency "config"
  s.add_dependency "nokogiri"
end
