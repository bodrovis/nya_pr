# frozen_string_literal: true

module NyaPr
  module PullRequest
    class Config < Data.define(
      :limit,
      :skip_drafts,
      :progress_enabled
    )
      DEFAULT_LIMIT = 100

      def self.from_app(config)
        new(
          limit: config.limit,
          skip_drafts: config.skip_drafts,
          progress_enabled: config.progress
        )
      end
    end
  end
end
