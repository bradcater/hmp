# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'hmp/version'

Gem::Specification.new do |gem|
  gem.name          = "hmp"
  gem.version       = Hmp::VERSION
  gem.authors       = ["Brad Cater"]
  gem.email         = ["bradcater@gmail.com"]
  gem.description   = %q{This gem adds ActiveRecord support for partitioned has_one relations using the PostgreSQL PARTITION BY clause.}
  gem.summary       = %q{This gem adds ActiveRecord support for partitioned has_one relations using the PostgreSQL PARTITION BY clause.}
  gem.homepage      = ""

  gem.files         = `git ls-files`.split($/)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.require_paths = ["lib"]

  gem.add_dependency "activerecord", "~> 3.0.20"
  gem.add_dependency "activesupport", "~> 3.0.20"
  gem.add_dependency "pg", "0.14.1"

  gem.add_development_dependency "rspec", "~> 2.13"
end
