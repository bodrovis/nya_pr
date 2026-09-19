# frozen_string_literal: true

module NyaPr
  module Config
    module Defaults
      LIMIT = 100
      WORKERS = 10

      OPTIONS = {
        owners: [],
        token: nil,
        repositories_csv: nil,
        pull_requests_dir: nil,
        limit: LIMIT,
        refresh: false,
        skip_archived: false,
        skip_drafts: false,
        exclude_repositories: [],
        save_pull_requests: true,
        progress: true,
        log_level: 'info',
        workers: WORKERS
      }.freeze
    end
  end
end
