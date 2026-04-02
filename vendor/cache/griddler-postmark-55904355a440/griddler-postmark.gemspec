# -*- encoding: utf-8 -*-
# stub: griddler-postmark 1.0.0 ruby lib

Gem::Specification.new do |s|
  s.name = "griddler-postmark".freeze
  s.version = "1.0.0".freeze

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Randy Schmidt".freeze]
  s.date = "1980-01-02"
  s.description = "Adapter to allow the use of Postmark Parse API with Griddler".freeze
  s.email = ["me@r38y.com".freeze]
  s.files = [".gitignore".freeze, ".rspec".freeze, ".travis.yml".freeze, "Gemfile".freeze, "LICENSE.txt".freeze, "README.md".freeze, "Rakefile".freeze, "griddler-postmark.gemspec".freeze, "lib/griddler/postmark.rb".freeze, "lib/griddler/postmark/adapter.rb".freeze, "lib/griddler/postmark/attachment.rb".freeze, "lib/griddler/postmark/version.rb".freeze, "spec/fixtures/photo1.jpg".freeze, "spec/fixtures/photo2.jpg".freeze, "spec/griddler/postmark/adapter_spec.rb".freeze, "spec/spec_helper.rb".freeze]
  s.homepage = "https://github.com/r38y/griddler-postmark".freeze
  s.licenses = ["MIT".freeze]
  s.rubygems_version = "3.7.2".freeze
  s.summary = "Postmark adapter for Griddler".freeze
  s.test_files = ["spec/fixtures/photo1.jpg".freeze, "spec/fixtures/photo2.jpg".freeze, "spec/griddler/postmark/adapter_spec.rb".freeze, "spec/spec_helper.rb".freeze]

  s.installed_by_version = "3.7.2".freeze

  s.specification_version = 4

  s.add_development_dependency(%q<bundler>.freeze, ["~> 1.6".freeze])
  s.add_development_dependency(%q<rake>.freeze, [">= 0".freeze])
  s.add_development_dependency(%q<rspec>.freeze, [">= 0".freeze])
  s.add_development_dependency(%q<pry>.freeze, [">= 0".freeze])
  s.add_runtime_dependency(%q<griddler>.freeze, [">= 0".freeze])
end
