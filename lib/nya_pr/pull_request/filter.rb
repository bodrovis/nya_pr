# frozen_string_literal: true

module NyaPr
  module PullRequest
    class Filter
      attr_reader :config

      def initialize(config)
        @config = config
      end

      def match?(pull_request)
        return false if config.skip_drafts && pull_request['draft']

        true
      end

      def ===(pull_request)
        match?(pull_request)
      end
    end
  end
end
