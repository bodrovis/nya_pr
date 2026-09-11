# frozen_string_literal: true

require 'zeitwerk'
require 'logger'

loader = Zeitwerk::Loader.for_gem
loader.setup

module NyaPr
  class << self
    def client(token, **)
      Client.new(token, **)
    end

    def logger
      @logger ||= Logger.new($stderr).tap do |logger|
        logger.level = Logger::INFO
        logger.progname = 'nya-pr'
      end
    end

    def run(argv = ARGV)
      Runner.new(argv).run
    end
  end
end
