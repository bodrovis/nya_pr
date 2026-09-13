# frozen_string_literal: true

RSpec.describe NyaPr::Repository::Filter do
  subject(:filter) { described_class.new(client, config) }

  let(:client) { NyaPr::Client.new('test-token') }

  let(:config) do
    NyaPr::Repository::Config.new(
      username: 'nya-user',
      owners: ['nya-user'],
      refresh: false,
      skip_archived: false,
      progress_enabled: false,
      workers: 2
    )
  end

  let(:repositories) do
    [
      { 'full_name' => 'example/one' },
      { 'full_name' => 'example/two' },
      { 'full_name' => 'example/three' }
    ]
  end

  it 'returns only repositories the user contributed to' do
    stub_request(
      :get,
      'https://api.github.com/repos/example/one/commits'
    ).
      with(
        query: {
          author: 'nya-user',
          per_page: 1
        }
      ).
      to_return(
        status: 200,
        body: Oj.dump([{ 'sha' => 'abc' }])
      )

    stub_request(
      :get,
      'https://api.github.com/repos/example/two/commits'
    ).
      with(
        query: {
          author: 'nya-user',
          per_page: 1
        }
      ).
      to_return(
        status: 200,
        body: Oj.dump([])
      )

    stub_request(
      :get,
      'https://api.github.com/repos/example/three/commits'
    ).
      with(
        query: {
          author: 'nya-user',
          per_page: 1
        }
      ).
      to_return(
        status: 200,
        body: Oj.dump([{ 'sha' => 'def' }])
      )

    expect(filter.contributed(repositories)).to eq(
      [
        { 'full_name' => 'example/one' },
        { 'full_name' => 'example/three' }
      ]
    )
  end

  it 'treats a 409 response as an empty repository' do
    repository = { 'full_name' => 'example/empty' }

    stub_request(
      :get,
      'https://api.github.com/repos/example/empty/commits'
    ).
      with(
        query: {
          author: 'nya-user',
          per_page: 1
        }
      ).
      to_return(
        status: 409,
        body: Oj.dump(message: 'Git Repository is empty.')
      )

    expect(filter.contributed([repository])).to be_empty
  end

  it 'raises other GitHub errors' do
    repository = { 'full_name' => 'example/broken' }

    stub_request(
      :get,
      'https://api.github.com/repos/example/broken/commits'
    ).
      with(
        query: {
          author: 'nya-user',
          per_page: 1
        }
      ).
      to_return(
        status: 500,
        body: Oj.dump(message: 'Server error')
      )

    expect { filter.contributed([repository]) }.
      to raise_error(NyaPr::Error)
  end
end
