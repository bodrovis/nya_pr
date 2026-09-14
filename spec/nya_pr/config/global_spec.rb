# frozen_string_literal: true

RSpec.describe NyaPr::Config::Global do
  describe '.from_options' do
    it 'uses default values when options are not provided' do
      config = described_class.from_options(
        {
          username: 'nya-user'
        }
      )

      expect(config).to have_attributes(
        username: 'nya-user',
        owners: [],
        limit: 100,
        refresh: false,
        skip_archived: false,
        skip_drafts: false,
        progress: true,
        log_level: Logger::INFO
      )
    end

    it 'uses values from the config file' do
      config = described_class.from_options(
        {},
        file_options: {
          username: 'yaml-user',
          owners: %w[org-one org-two],
          limit: 200,
          skip_archived: true,
          progress: false,
          log_level: 'debug'
        }
      )

      expect(config).to have_attributes(
        username: 'yaml-user',
        owners: %w[org-one org-two],
        limit: 200,
        skip_archived: true,
        progress: false,
        log_level: Logger::DEBUG
      )
    end

    it 'gives command line options precedence over config file options' do
      config = described_class.from_options(
        {
          username: 'cli-user',
          limit: 50,
          progress: false
        },
        file_options: {
          username: 'yaml-user',
          owners: ['nya-org'],
          limit: 200,
          progress: true,
          skip_drafts: true
        }
      )

      expect(config).to have_attributes(
        username: 'cli-user',
        owners: ['nya-org'],
        limit: 50,
        progress: false,
        skip_drafts: true
      )
    end

    it 'normalizes owners from different input formats' do
      config = described_class.from_options(
        {
          username: 'nya-user',
          owners: ['org-one, org-two', 'org-three']
        }
      )

      expect(config.owners).to eq(
        %w[org-one org-two org-three]
      )
    end

    it 'rejects unknown config file options' do
      expect do
        described_class.from_options(
          {},
          file_options: {
            username: 'nya-user',
            skip_darfts: true
          }
        )
      end.to raise_error(
        NyaPr::Error,
        'Unknown config option(s): skip_darfts'
      )
    end
  end

  it 'rejects invalid boolean values' do
    expect do
      described_class.from_options(
        {},
        file_options: {
          username: 'nya-user',
          skip_drafts: 'yes'
        }
      )
    end.to raise_error(
      NyaPr::Error,
      'skip_drafts must be true or false'
    )
  end
end
