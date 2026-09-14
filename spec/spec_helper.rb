# frozen_string_literal: true

require 'webmock/rspec'
require 'tmpdir'
require 'oj'

require_relative '../lib/nya_pr'

Dir[File.join(__dir__, 'support/**/*.rb')].each do |file|
  require file
end

WebMock.disable_net_connect!

RSpec.configure do |config|
  config.order = :random

  config.include GitHubFixtures
  config.include GitHubStubs
  config.include TestHelpers
end
