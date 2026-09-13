# frozen_string_literal: true

require_relative 'lib/nya_pr/version'

Gem::Specification.new do |spec|
  spec.name = 'nya_pr'
  spec.version = NyaPr::VERSION
  spec.authors = ['Elijah S. Krukowski']
  spec.email = ['elskruk@proton.me']
  spec.summary = 'A tiny kawaii CLI for hunting down GitHub pull requests'

  spec.description = <<~DESCRIPTION
    NyaPr collects repositories you own or contribute to, finds their open pull
    requests, and puts them together in one place for maximum kawaii.
  DESCRIPTION

  spec.homepage = 'https://github.com/bodrovis/nya_pr'
  spec.license = 'MIT'

  spec.required_ruby_version = '>= 4.0'

  spec.files = Dir[
    'lib/**/*',
    'exe/*',
    'LICENSE.md',
    'README.md'
  ]

  spec.require_paths = ['lib']

  spec.add_dependency 'csv', '~> 3.3'
  spec.add_dependency 'dotenv', '~> 3.2'
  spec.add_dependency 'faraday', '~> 2.14'
  spec.add_dependency 'oj', '~> 3.10'
  spec.add_dependency 'zeitwerk', '~> 2.6'

  spec.metadata = {
    'rubygems_mfa_required' => 'true',
    'bug_tracker_uri' => 'https://github.com/bodrovis/nya_pr/issues',
    'documentation_uri' => 'https://github.com/bodrovis/nya_pr/blob/master/README.md',
    'homepage_uri' => spec.homepage
  }
end
