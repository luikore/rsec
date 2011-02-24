Gem::Specification.new do |s|
  s.name = "rsec"
  s.version = "0.3.2"
  s.author = "NS"
  s.homepage = "http://rsec.heroku.com"
  s.platform = Gem::Platform::RUBY
  s.summary = "Extreme Fast Parser Combinator for Ruby"
  s.description = "Easy and extreme fast dynamic PEG parser combinator."
  s.required_ruby_version = ">=1.9.1"

  s.files = Dir.glob("{license.txt,readme.rdoc,lib/**/*.rb,examples/*.rb,examples/*.scm,test/*.rb,bench/*.rb}")
  s.require_paths = ["lib"]
  s.rubygems_version = '1.3.7'
  # s.has_rdoc = false
  s.extra_rdoc_files = ["readme.rdoc"]
end

