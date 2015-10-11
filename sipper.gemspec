require 'rubygems' 
require 'sipper/version'

SPEC = Gem::Specification.new do |s| 
   s.name          = "Sipper" 
   s.version       =  "#{SIP::VERSION::STRING}"
   s.author        = "Agnity Inc. Canada" 
   s.email         = "nasir.khan@agnity.com" 
   s.platform      = Gem::Platform::RUBY
   s.description   = "Simplifying SIP testing for everyone, guaranteed to cut down testing time by half or more"
   s.homepage      = "http://sipper.agnity.com"
   s.rubyforge_project = "sipper" 
   s.summary       = "Sipper - World's most productive SIP platform" 
   s.files         = Dir.glob("{sipper,sipper_test,Rakefile,bin}/**/*") 
   s.require_path  = "." 
   s.has_rdoc       = false 
   s.bindir = "bin"
   s.executables = ["srun", "ssmoke", "sproj", "sgen"]
   s.add_dependency("facets", ">= 3.0.0")
   s.add_dependency("flexmock", ">= 2.0.0")
   s.add_dependency("log4r", ">= 1.1.10")
end  
