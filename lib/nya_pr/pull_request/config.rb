# frozen_string_literal: true

module NyaPr
  module PullRequest
    Config = Data.define(
      :limit,
      :skip_drafts,
      :progress_enabled,
      :pull_requests_dir
    ) do
      def self.from_app(config)
        new(
          limit: config.limit,
          skip_drafts: config.skip_drafts,
          progress_enabled: config.progress,
          pull_requests_dir: config.pull_requests_dir
        )
      end
    end
  end
end
