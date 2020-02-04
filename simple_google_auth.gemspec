$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "simple_google_auth/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "simple_google_auth"
  s.version     = SimpleGoogleAuth::VERSION
  s.authors     = ["Roger Nesbitt"]
  s.email       = ["roger@seriousorange.com"]
  s.homepage    = "https://github.com/mogest/simple_google_auth"
  s.summary     = "Super simple Google authentication for your Rails site"
  s.description = "An extremely easy way to protect your site by requiring Google logins without having to set up a traditional authentication system"
  s.license     = "MIT"

  s.files = Dir["{config,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.md"]
  s.test_files = Dir["spec/**/*"]

  s.required_ruby_version = '>= 2.0.0'

  s.add_dependency "rails", ENV['RAILS_VERSION'] || ">= 5.2"
  s.add_development_dependency 'rspec-rails', '~> 3.9'
end
