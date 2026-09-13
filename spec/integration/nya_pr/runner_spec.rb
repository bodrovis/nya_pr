# frozen_string_literal: true

RSpec.describe NyaPr::Runner do
  let(:token) { 'test-token' }

  before do
    stub_const(
      'ENV',
      ENV.to_h.merge('GITHUB_TOKEN' => token)
    )
  end

  it 'collects relevant repositories and writes open pull requests' do
    Dir.mktmpdir do |dir|
      repositories_csv = File.join(dir, 'repositories.csv')
      pull_requests_dir = File.join(dir, 'pull_requests')

      stub_github

      args = [
        '--user', 'nya-user',
        '--owners', 'nya-org',
        '--repositories-csv', repositories_csv,
        '--pull-requests-dir', pull_requests_dir,
        '--skip-archived'
      ]

      described_class.new(args).run

      expect(File).to exist(repositories_csv)

      repositories = CSV.read(repositories_csv, headers: true)

      expect(repositories['full_name']).to contain_exactly(
        'nya-user/personal-repo',
        'nya-org/contributed-repo'
      )

      pull_request_files = Dir[
        File.join(
          pull_requests_dir,
          'pull_requests_*',
          'pull_requests.csv'
        )
      ]

      expect(pull_request_files.size).to eq(1)

      pull_requests = CSV.read(
        pull_request_files.first,
        headers: true
      )

      expect(pull_requests['repository']).to contain_exactly(
        'nya-user/personal-repo',
        'nya-org/contributed-repo'
      )
    end
  end

  it 'uses cached repositories without scanning GitHub again' do
    Dir.mktmpdir do |dir|
      repositories_csv = File.join(dir, 'repositories.csv')
      pull_requests_dir = File.join(dir, 'pull_requests')

      write_repository_cache(
        repositories_csv,
        [
          repository('nya-user/cached-repo'),
          repository('nya-org/cached-contributed-repo')
        ]
      )

      stub_pull_requests_for(
        'nya-user/cached-repo',
        [pull_request(10, 'nya-user')]
      )

      stub_pull_requests_for(
        'nya-org/cached-contributed-repo',
        [pull_request(20, 'somebody')]
      )

      args = [
        '--user', 'nya-user',
        '--owners', 'nya-org',
        '--repositories-csv', repositories_csv,
        '--pull-requests-dir', pull_requests_dir,
        '--log-level', 'fatal'
      ]

      described_class.new(args).run

      expect(
        a_request(:get, %r{api\.github\.com/user/repos})
      ).not_to have_been_made

      expect(
        a_request(:get, %r{api\.github\.com/users/})
      ).not_to have_been_made

      expect(
        a_request(:get, %r{api\.github\.com/orgs/})
      ).not_to have_been_made

      expect(
        a_request(:get, %r{/commits})
      ).not_to have_been_made

      expect(
        a_request(:get, %r{/pulls})
      ).to have_been_made.twice
    end
  end

  it 'refreshes cached repositories when --refresh is used' do
    Dir.mktmpdir do |dir|
      repositories_csv = File.join(dir, 'repositories.csv')
      pull_requests_dir = File.join(dir, 'pull_requests')

      write_repository_cache(
        repositories_csv,
        [
          repository('nya-user/old-cached-repo')
        ]
      )

      stub_owner('nya-org', type: 'Organization')
      stub_personal_repositories
      stub_organization_repositories
      stub_contributions
      stub_pull_requests

      args = [
        '--user', 'nya-user',
        '--owners', 'nya-org',
        '--repositories-csv', repositories_csv,
        '--pull-requests-dir', pull_requests_dir,
        '--refresh',
        '--skip-archived',
        '--log-level', 'fatal'
      ]

      described_class.new(args).run

      expect(
        a_request(
          :get,
          %r{api\.github\.com/user/repos}
        )
      ).to have_been_made.once

      expect(
        a_request(
          :get,
          'https://api.github.com/users/nya-org'
        )
      ).to have_been_made.once

      expect(
        a_request(
          :get,
          %r{api\.github\.com/orgs/nya-org/repos}
        )
      ).to have_been_made.once

      expect(
        a_request(
          :get,
          %r{/repos/nya-org/contributed-repo/commits}
        )
      ).to have_been_made.once

      expect(
        a_request(
          :get,
          %r{/repos/nya-org/unrelated-repo/commits}
        )
      ).to have_been_made.once

      expect(
        a_request(
          :get,
          %r{/repos/nya-org/ancient-repo/commits}
        )
      ).not_to have_been_made

      repositories = CSV.read(
        repositories_csv,
        headers: true
      )

      expect(repositories['full_name']).to contain_exactly(
        'nya-user/personal-repo',
        'nya-org/contributed-repo'
      )

      expect(repositories['full_name']).not_to include(
        'nya-user/old-cached-repo'
      )

      expect(
        a_request(
          :get,
          %r{/repos/nya-user/old-cached-repo/pulls}
        )
      ).not_to have_been_made
    end
  end
end
