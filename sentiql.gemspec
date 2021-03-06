# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "sentiql/version"

Gem::Specification.new do |s|
  s.name        = "sentiql"
  s.version     = SentiQL::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["Martynas Miliauskas"]
  s.email       = ["miliauskas@facebook.com"]
  s.homepage    = ""
  s.summary     = %q{A minimalistic Ruby wrapper for MySQL}
  s.description = %q{This is a work in progress. SentiQL promotes use of SQL for data selection, OM for CUD operations and being as lean as possible.}

  s.rubyforge_project = "sentiql"

  s.add_runtime_dependency 'mysql2', '< 0.3'

  s.add_development_dependency 'rspec'
  s.add_development_dependency 'database_cleaner'
  s.add_development_dependency 'activerecord', '~> 3.0.5'

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]
end
