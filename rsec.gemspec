Gem::Specification.new do |s|
  s.name = "rsec"
  s.version = "0.0.9"
  s.author = "NS"
  s.email = "usurffx@gmail.com"
  s.homepage = "http://wiki.github.com/luikore/rsec"
  s.platform = Gem::Platform::RUBY
  s.summary = "Extreme Fast Parser Combinator for Ruby"
  s.description = "Easy and extreme fast dynamic PEG parser combinator.
It's like Haskell Parsec but goes the Ruby way.
With C-extension, it can be 30% faster than Haskell Parsec."
  s.required_ruby_version = ">=1.9.1"

  s.files = Dir.glob("{rakefile,license.txt,readme.rdoc,lib/**/*.rb,examples/*.rb,examples/*.scm,test/*.rb,bench/*.rb,ext/rsec/predef.c,ext/rsec/extconf.rb}")
  s.extensions = ['ext/rsec/extconf.rb']
  s.require_paths = ["lib", "ext"]
  s.rubygems_version = '1.3.5'
  # s.has_rdoc = false
  s.extra_rdoc_files = ["readme.rdoc"]
end

