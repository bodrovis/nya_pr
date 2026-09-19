# frozen_string_literal: true

module NyaPr
  module Repository
    Config = Data.define(
      :username,
      :owners,
      :refresh,
      :skip_archived,
      :progress_enabled,
      :workers,
      :repositories_csv,
      :exclude_repositories
    ) do
      def self.from_app(config)
        new(
          username: config.username,
          owners: ([config.username] + config.owners).uniq,
          refresh: config.refresh,
          skip_archived: config.skip_archived,
          progress_enabled: config.progress,
          workers: config.workers,
          repositories_csv: config.repositories_csv,
          exclude_repositories: config.exclude_repositories
        )
      end
    end
  end
end
