# frozen_string_literal: true

require 'zeitwerk'
require 'logger'
require 'csv'
require 'dry/cli'

loader = Zeitwerk::Loader.for_gem
loader.setup

module NyaPr
  class << self
    def run(argv = ARGV)
      Dry::CLI.new(Cli::Command).call(arguments: argv)
    end

    def logger
      @logger ||= Logger.new($stderr).tap do |logger|
        logger.level = Logger::INFO
        logger.progname = 'nya-pr'
      end
    end
  end
end
