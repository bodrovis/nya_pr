# frozen_string_literal: true

RSpec.describe NyaPr::Repository::Collector do
  subject(:collector) do
    described_class.new(
      client,
      store,
      config
    )
  end

  let(:client) { NyaPr::Client.new('test-token') }
  let(:store) { instance_double(NyaPr::Repository::CsvStore) }

  let(:config) do
    NyaPr::Repository::Config.new(
      username: 'nya-user',
      owners: ['nya-user'],
      refresh: false,
      skip_archived: false,
      progress_enabled: false,
      workers: 1
    )
  end

  before do
    allow(store).to receive(:path).and_return('repositories.csv')
  end

  context 'when cached repositories are available' do
    let(:repositories) do
      [
        {
          'full_name' => 'nya-user/example',
          'owner' => { 'login' => 'nya-user' }
        }
      ]
    end

    before do
      allow(store).to receive_messages(
        available?: true,
        read: repositories,
        write: nil
      )
    end

    it 'loads repositories from the cache' do
      expect(collector.collect).to eq(repositories)

      expect(store).to have_received(:read)
      expect(store).not_to have_received(:write)
    end
  end

  context 'when repositories need to be discovered' do
    let(:finder) { instance_double(NyaPr::Repository::Finder) }
    let(:filter) { instance_double(NyaPr::Repository::Filter) }

    let(:own_repository) do
      {
        'full_name' => 'nya-user/own',
        'owner' => { 'login' => 'nya-user' }
      }
    end

    let(:external_repository) do
      {
        'full_name' => 'nya-org/external',
        'owner' => { 'login' => 'nya-org' }
      }
    end

    before do
      allow(store).to receive(:available?).and_return(false)
      allow(store).to receive(:write)

      allow(NyaPr::Repository::Finder).
        to receive(:new).
        with(client, config).
        and_return(finder)

      allow(finder).
        to receive(:repositories_for).
        and_return(
          [
            own_repository,
            external_repository
          ]
        )

      allow(NyaPr::Repository::Filter).
        to receive(:new).
        with(client, config).
        and_return(filter)

      allow(filter).
        to receive(:contributed).
        with([external_repository]).
        and_return([external_repository])
    end

    it 'keeps owned repositories and checks contributions for external ones' do
      repositories = collector.collect

      expect(repositories).to eq(
        [
          own_repository,
          external_repository
        ]
      )

      expect(filter).
        to have_received(:contributed).
        with([external_repository])

      expect(store).
        to have_received(:write).
        with(repositories)
    end
  end

  context 'when archived repositories are skipped' do
    let(:config) do
      NyaPr::Repository::Config.new(
        username: 'nya-user',
        owners: ['nya-user'],
        refresh: false,
        skip_archived: true,
        progress_enabled: false,
        workers: 1
      )
    end

    let(:repositories) do
      [
        {
          'full_name' => 'nya-user/active',
          'owner' => { 'login' => 'nya-user' },
          'archived' => false
        },
        {
          'full_name' => 'nya-user/archived',
          'owner' => { 'login' => 'nya-user' },
          'archived' => true
        }
      ]
    end

    before do
      allow(store).to receive_messages(available?: true, read: repositories)
    end

    it 'removes archived repositories from cached results' do
      expect(collector.collect).to eq(
        [
          repositories.first
        ]
      )
    end
  end
end
