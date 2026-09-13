# frozen_string_literal: true

module GitHubStubs
  def stub_github
    stub_owner('nya-org', type: 'Organization')

    stub_personal_repositories
    stub_organization_repositories
    stub_contributions
    stub_pull_requests
  end

  def stub_personal_repositories
    stub_request(
      :get,
      %r{api\.github\.com/user/repos}
    ).to_return(
      status: 200,
      body: Oj.dump([
                      repository('nya-user/personal-repo')
                    ])
    )
  end

  def stub_organization_repositories
    stub_request(
      :get,
      %r{api\.github\.com/orgs/nya-org/repos}
    ).to_return(
      status: 200,
      body: Oj.dump([
                      repository('nya-org/contributed-repo'),
                      repository('nya-org/unrelated-repo'),
                      repository('nya-org/ancient-repo', archived: true)
                    ])
    )
  end

  def stub_contributions
    stub_request(
      :get,
      %r{api\.github\.com/repos/nya-org/contributed-repo/commits}
    ).to_return(
      status: 200,
      body: Oj.dump([{ 'sha' => 'abc123' }])
    )

    stub_request(
      :get,
      %r{api\.github\.com/repos/nya-org/unrelated-repo/commits}
    ).to_return(
      status: 200,
      body: Oj.dump([])
    )
  end

  def stub_pull_requests
    stub_request(
      :get,
      %r{api\.github\.com/repos/nya-user/personal-repo/pulls}
    ).to_return(
      status: 200,
      body: Oj.dump([
                      pull_request(1, 'nya-user')
                    ])
    )

    stub_request(
      :get,
      %r{api\.github\.com/repos/nya-org/contributed-repo/pulls}
    ).to_return(
      status: 200,
      body: Oj.dump([
                      pull_request(42, 'somebody')
                    ])
    )
  end

  def stub_owner(owner, type:)
    stub_request(
      :get,
      "https://api.github.com/users/#{owner}"
    ).to_return(
      status: 200,
      body: Oj.dump(
        'login' => owner,
        'type' => type
      )
    )
  end

  def stub_pull_requests_for(repository, pull_requests)
    stub_request(
      :get,
      %r{api\.github\.com/repos/#{Regexp.escape(repository)}/pulls}
    ).to_return(
      status: 200,
      body: Oj.dump(pull_requests)
    )
  end
end
