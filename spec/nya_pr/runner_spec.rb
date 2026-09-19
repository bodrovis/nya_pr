# frozen_string_literal: true

RSpec.describe NyaPr::Runner do
  subject(:runner) do
    described_class.new(
      repository_collector: repository_collector,
      pull_request_finder: pull_request_finder,
      pull_request_printer: printer,
      pull_request_store: nil
    )
  end

  let(:repositories) do
    [
      {
        'full_name' => 'nya-user/example'
      }
    ]
  end

  let(:pull_requests) do
    [
      {
        'repository' => 'nya-user/example',
        'number' => 42,
        'title' => 'Nya PR'
      }
    ]
  end

  let(:repository_collector) do
    instance_double(
      NyaPr::Repository::Collector,
      collect: repositories
    )
  end

  let(:pull_request_finder) do
    instance_double(
      NyaPr::PullRequest::Finder,
      find: pull_requests
    )
  end

  let(:printer) do
    instance_double(
      NyaPr::PullRequest::Printer,
      print: nil
    )
  end

  context 'when saving pull requests is enabled' do
    subject(:runner) do
      described_class.new(
        repository_collector: repository_collector,
        pull_request_finder: pull_request_finder,
        pull_request_printer: printer,
        pull_request_store: store
      )
    end

    let(:store) do
      instance_double(
        NyaPr::PullRequest::CsvStore,
        write: nil,
        path: 'pull_requests.csv'
      )
    end

    it 'saves pull requests' do
      runner.run

      expect(store).
        to have_received(:write).
        with(pull_requests)
    end
  end

  context 'when saving pull requests is disabled' do
    it 'prints pull requests without saving them' do
      runner.run

      expect(pull_request_finder).
        to have_received(:find).
        with(repositories)

      expect(printer).
        to have_received(:print).
        with(pull_requests)
    end
  end
end
