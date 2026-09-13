# frozen_string_literal: true

module ConfigHelpers
  def config(**overrides)
    defaults = {
      username: 'nya-user',
      owners: [],
      token: 'test-token',
      repositories_csv: nil,
      pull_requests_dir: nil,
      limit: 100,
      refresh: false,
      skip_archived: false,
      skip_drafts: false,
      progress: false,
      log_level: Logger::FATAL
    }

    NyaPr::Config.new(**defaults, **overrides)
  end
end
