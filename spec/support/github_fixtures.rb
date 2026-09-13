# frozen_string_literal: true

module GitHubFixtures
  def repository(full_name, archived: false, pull_requests: true)
    owner, = full_name.split('/')

    {
      'full_name' => full_name,
      'html_url' => "https://github.com/#{full_name}",
      'visibility' => 'public',
      'private' => false,
      'archived' => archived,
      'has_pull_requests' => pull_requests,
      'owner' => {
        'login' => owner
      }
    }
  end

  def pull_request(number, author, draft: false)
    {
      'number' => number,
      'title' => "Pull request #{number}",
      'user' => {
        'login' => author
      },
      'draft' => draft,
      'created_at' => '2026-09-01T10:00:00Z',
      'updated_at' => '2026-09-02T10:00:00Z',
      'html_url' => "https://github.com/nya-user/example/pull/#{number}"
    }
  end
end
