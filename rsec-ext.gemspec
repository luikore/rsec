YAML::ENGINE.yamler = 'syck'
Gem::Specification.new do |s|
  s.name = "rsec-ext"
  s.version = "0.3.5"
  s.author = "NS"
  s.homepage = "http://rsec.heroku.com"
  s.platform = Gem::Platform::RUBY
  s.summary = "Extreme Fast Parser Combinator for Ruby, the C extension part"
  s.description = "Easy and extreme fast dynamic PEG parser combinator."
  s.required_ruby_version = ">=1.9.1"

  s.files = Dir.glob("{license.txt,readme.rdoc,ext/rsec/ext.rb,ext/rsec/predef.c,ext/rsec/extconf.rb}")
  s.extensions = ['ext/rsec/extconf.rb']
  s.require_paths = ["ext"]
  s.rubygems_version = '1.6.1'
  # s.has_rdoc = false
  s.extra_rdoc_files = ["readme.rdoc"]

  s.add_dependency 'rsec', ['=0.3.5']

  if s.respond_to? :specification_version
    s.specification_version = 3
  end
end

