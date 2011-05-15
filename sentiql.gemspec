# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "sentiql/version"

Gem::Specification.new do |s|
  s.name        = "sentiql"
  s.version     = Sentiql::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["Martynas Miliauskas"]
  s.email       = ["miliauskas@facebook.com"]
  s.homepage    = ""
  s.summary     = %q{A minimalistic Ruby wrapper for MySQL}
  s.description = %q{This is a work in progress. SentiQL promotes use of SQL for data selection, OM for CUD operations and being as lean as possible.}

  s.rubyforge_project = "sentiql"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]
end
