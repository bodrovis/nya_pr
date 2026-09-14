# frozen_string_literal: true

RSpec.describe NyaPr::Repository::Finder do
  subject(:finder) { described_class.new(client, config) }

  let(:client) { github_client }

  let(:config) { repository_config(owners: owners) }

  context 'when collecting repositories owned by the current user' do
    let(:owners) { ['nya-user'] }

    it 'collects all repositories owned by the authenticated user' do
      stub_request(:get, 'https://api.github.com/user/repos').
        with(
          query: {
            affiliation: 'owner',
            visibility: 'all',
            per_page: 100,
            page: 1
          }
        ).
        to_return(
          status: 200,
          body: Oj.dump(
            [
              { 'full_name' => 'nya-user/one' },
              { 'full_name' => 'nya-user/two' }
            ]
          )
        )

      repositories = finder.repositories_for

      expect(
        repositories.map { |repository| repository['full_name'] }
      ).to eq(
        [
          'nya-user/one',
          'nya-user/two'
        ]
      )
    end
  end

  context 'when collecting repositories from an organization' do
    let(:owners) { ['nya-org'] }

    it 'detects the organization and collects its repositories' do
      stub_request(
        :get,
        'https://api.github.com/users/nya-org'
      ).
        to_return(
          status: 200,
          body: Oj.dump('type' => 'Organization')
        )

      stub_request(
        :get,
        'https://api.github.com/orgs/nya-org/repos'
      ).
        with(
          query: {
            type: 'all',
            per_page: 100,
            page: 1
          }
        ).
        to_return(
          status: 200,
          body: Oj.dump(
            [
              { 'full_name' => 'nya-org/example' }
            ]
          )
        )

      repositories = finder.repositories_for

      expect(
        repositories.map { |repository| repository['full_name'] }
      ).to eq(['nya-org/example'])
    end
  end

  context 'when collecting repositories from another user' do
    let(:owners) { ['other-user'] }

    it 'detects the user and collects repositories they own' do
      stub_request(
        :get,
        'https://api.github.com/users/other-user'
      ).
        to_return(
          status: 200,
          body: Oj.dump('type' => 'User')
        )

      stub_request(
        :get,
        'https://api.github.com/users/other-user/repos'
      ).
        with(
          query: {
            type: 'owner',
            per_page: 100,
            page: 1
          }
        ).
        to_return(
          status: 200,
          body: Oj.dump(
            [
              { 'full_name' => 'other-user/example' }
            ]
          )
        )

      repositories = finder.repositories_for

      expect(
        repositories.map { |repository| repository['full_name'] }
      ).to eq(['other-user/example'])
    end
  end

  context 'when the owner type is unsupported' do
    let(:owners) { ['weird-owner'] }

    it 'raises an error' do
      stub_request(
        :get,
        'https://api.github.com/users/weird-owner'
      ).
        to_return(
          status: 200,
          body: Oj.dump('type' => 'Bot')
        )

      expect { finder.repositories_for }.
        to raise_error(
          NyaPr::Error,
          'Unsupported GitHub owner type: weird-owner'
        )
    end
  end
end
