# frozen_string_literal: true

RSpec.describe NyaPr::PullRequest::Finder do
  subject(:finder) do
    described_class.new(
      client,
      config
    )
  end

  let(:client) { github_client }
  let(:pulls_url) { 'https://api.github.com/repos/nya-user/example/pulls' }

  let(:repositories) do
    [
      {
        'full_name' => 'nya-user/example',
        'has_pull_requests' => true
      }
    ]
  end

  context 'when drafts are skipped' do
    let(:config) do
      pull_request_config(
        limit: 2,
        skip_drafts: true
      )
    end

    it 'continues fetching pull requests after filtering out drafts' do
      stub_request(:get, pulls_url).
        with(
          query: {
            state: 'open',
            sort: 'updated',
            direction: 'desc',
            per_page: 2,
            page: 1
          }
        ).
        to_return(
          status: 200,
          body: Oj.dump(
            [
              pull_request(1, 'alice', draft: true),
              pull_request(2, 'bob')
            ]
          )
        )

      stub_request(:get, pulls_url).
        with(
          query: {
            state: 'open',
            sort: 'updated',
            direction: 'desc',
            per_page: 2,
            page: 2
          }
        ).
        to_return(
          status: 200,
          body: Oj.dump(
            [
              pull_request(3, 'carol')
            ]
          )
        )

      pull_requests = finder.find(repositories)

      expect(
        pull_requests.map { |pull_request| pull_request['number'] }
      ).to eq([2, 3])

      expect(pull_requests).to all(
        satisfy { |pull_request| !pull_request['draft'] }
      )

      expect(
        a_request(:get, pulls_url).with(
          query: {
            state: 'open',
            sort: 'updated',
            direction: 'desc',
            per_page: 2,
            page: 1
          }
        )
      ).to have_been_made.once

      expect(
        a_request(:get, pulls_url).with(
          query: {
            state: 'open',
            sort: 'updated',
            direction: 'desc',
            per_page: 2,
            page: 2
          }
        )
      ).to have_been_made.once
    end
  end

  context 'when drafts are allowed' do
    let(:config) do
      pull_request_config(
        limit: 2
      )
    end

    it 'returns normalized pull requests' do
      stub_request(:get, pulls_url).
        with(
          query: {
            state: 'open',
            sort: 'updated',
            direction: 'desc',
            per_page: 2,
            page: 1
          }
        ).
        to_return(
          status: 200,
          body: Oj.dump(
            [
              pull_request(1, 'alice'),
              pull_request(2, 'bob')
            ]
          )
        )

      pull_requests = finder.find(repositories)

      expect(
        pull_requests.map { |pull_request| pull_request['number'] }
      ).to eq([1, 2])

      expect(
        pull_requests.map { |pull_request| pull_request['author'] }
      ).to eq(%w[alice bob])
    end
  end

  context 'when pull requests are disabled for the repository' do
    let(:repositories) do
      [
        {
          'full_name' => 'nya-user/example',
          'has_pull_requests' => false
        }
      ]
    end

    let(:config) do
      pull_request_config(
        limit: 2
      )
    end

    it 'does not request pull requests' do
      expect(finder.find(repositories)).to be_empty

      expect(
        a_request(:get, %r{/repos/nya-user/example/pulls})
      ).not_to have_been_made
    end
  end
end
