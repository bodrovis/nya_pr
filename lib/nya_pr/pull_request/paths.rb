# frozen_string_literal: true

require 'fileutils'

module NyaPr
  module PullRequest
    class Paths
      DEFAULT_DIR = 'data'
      FILENAME = 'pull_requests.csv'

      attr_reader :config

      def initialize(config, timestamp: Time.now)
        @config = config
        @timestamp = timestamp
      end

      def csv
        path = run_dir.join(FILENAME)

        FileUtils.mkdir_p(path.dirname)

        path.to_s
      end

      private

      attr_reader :timestamp

      def run_dir
        @run_dir ||= Pathname.
                     new(config.pull_requests_dir || DEFAULT_DIR).
                     join("pull_requests_#{formatted_timestamp}")
      end

      def formatted_timestamp
        timestamp.strftime('%Y%m%d_%H%M%S')
      end
    end
  end
end
