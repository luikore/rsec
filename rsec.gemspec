YAML::ENGINE.yamler = 'syck'
Gem::Specification.new do |s|
  s.name = "rsec"
  s.version = "0.4.1"
  s.author = "NS"
  s.homepage = "http://rsec.herokuapp.com"
  s.platform = Gem::Platform::RUBY
  s.summary = "Extreme Fast Parser Combinator for Ruby"
  s.description = "Easy and extreme fast dynamic PEG parser combinator."
  s.required_ruby_version = ">=1.9.1"

  s.files = Dir.glob("{license.txt,readme.rdoc,lib/**/*.rb,examples/*.rb,examples/*.scm,test/*.rb,bench/*.rb}")
  s.require_paths = ["lib"]
  s.rubygems_version = '1.8.11'
  # s.has_rdoc = false
  s.extra_rdoc_files = ["readme.rdoc"]

  if s.respond_to? :specification_version
    s.specification_version = 3
  end
end

