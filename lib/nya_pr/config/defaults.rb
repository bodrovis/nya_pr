# frozen_string_literal: true

module NyaPr
  module Config
    module Defaults
      OPTIONS = {
        owners: [],
        token: nil,
        repositories_csv: nil,
        pull_requests_dir: nil,
        limit: 100,
        refresh: false,
        skip_archived: false,
        skip_drafts: false,
        exclude_repositories: [],
        save_pull_requests: true,
        progress: true,
        log_level: 'info',
        workers: 30
      }.freeze
    end
  end
end
