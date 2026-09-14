# frozen_string_literal: true

module TestHelpers
  def repository_config(**overrides)
    defaults = {
      username: 'nya-user',
      owners: ['nya-user'],
      progress_enabled: false,
      refresh: false,
      workers: 1,
      skip_archived: false,
      repositories_csv: nil,
      exclude_repositories: []
    }

    NyaPr::Repository::Config.new(
      **defaults,
      **overrides
    )
  end

  def pull_request_config(**overrides)
    defaults = {
      limit: NyaPr::PullRequest::Config::DEFAULT_LIMIT,
      skip_drafts: false,
      progress_enabled: false,
      pull_requests_dir: nil
    }

    NyaPr::PullRequest::Config.new(
      **defaults,
      **overrides
    )
  end

  def github_client(token = 'test-token')
    NyaPr::Github::Client.new(token)
  end

  def write_repository_cache(path, repositories)
    NyaPr::Repository::CsvStore.
      new(path).
      write(repositories)
  end
end
