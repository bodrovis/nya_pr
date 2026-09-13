# frozen_string_literal: true

module NyaPr
  module Repository
    class Config < Data.define(
      :username,
      :owners,
      :refresh,
      :skip_archived,
      :progress_enabled,
      :workers
    )
      DEFAULT_WORKERS = 10

      def self.from_app(config)
        new(
          username: config.username,
          owners: ([config.username] + config.owners).uniq,
          refresh: config.refresh,
          skip_archived: config.skip_archived,
          progress_enabled: config.progress,
          workers: DEFAULT_WORKERS
        )
      end
    end
  end
end
