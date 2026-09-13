# frozen_string_literal: true

RSpec.describe NyaPr::PullRequest::Filter do
  subject(:filter) { described_class.new(config) }

  let(:pull_request) do
    {
      'number' => 42,
      'draft' => draft
    }
  end

  context 'when drafts are skipped' do
    let(:config) do
      NyaPr::PullRequest::Config.new(
        limit: 100,
        skip_drafts: true,
        progress_enabled: false
      )
    end

    let(:draft) { true }

    it 'rejects draft pull requests' do
      expect(filter.match?(pull_request)).to be(false)
    end
  end

  context 'when drafts are allowed' do
    let(:config) do
      NyaPr::PullRequest::Config.new(
        limit: 100,
        skip_drafts: false,
        progress_enabled: false
      )
    end

    let(:draft) { true }

    it 'accepts draft pull requests' do
      expect(filter.match?(pull_request)).to be(true)
    end
  end

  describe '#===' do
    let(:config) do
      NyaPr::PullRequest::Config.new(
        limit: 100,
        skip_drafts: true,
        progress_enabled: false
      )
    end

    it 'works as a matcher for grep' do
      pull_requests = [
        { 'number' => 1, 'draft' => true },
        { 'number' => 2, 'draft' => false }
      ]

      expect(pull_requests.grep(filter)).to contain_exactly(
        { 'number' => 2, 'draft' => false }
      )
    end
  end
end
