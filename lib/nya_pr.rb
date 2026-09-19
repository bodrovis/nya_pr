# frozen_string_literal: true

require 'zeitwerk'
require 'logger'
require 'csv'
require 'dry/cli'
require 'dotenv'

loader = Zeitwerk::Loader.for_gem
loader.setup

module NyaPr
  class << self
    def run(argv = ARGV)
      Dotenv.load

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
