# frozen_string_literal: true

module NyaPr
  module Config
    Global = Data.define(
      :username,
      :owners,
      :token,
      :repositories_csv,
      :pull_requests_dir,
      :limit,
      :refresh,
      :skip_archived,
      :skip_drafts,
      :exclude_repositories,
      :save_pull_requests,
      :progress,
      :log_level,
      :workers
    )
  end
end
