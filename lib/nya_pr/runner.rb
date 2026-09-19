# frozen_string_literal: true

module NyaPr
  class Runner
    attr_reader :repository_collector,
                :pull_request_finder,
                :pull_request_printer,
                :pull_request_store

    def initialize(
      repository_collector:,
      pull_request_finder:,
      pull_request_printer:,
      pull_request_store:
    )
      @repository_collector = repository_collector
      @pull_request_finder = pull_request_finder
      @pull_request_printer = pull_request_printer
      @pull_request_store = pull_request_store
    end

    def run
      repositories = repository_collector.collect
      pull_requests = pull_request_finder.find(repositories)

      pull_request_printer.print(pull_requests)
      save_pull_requests(pull_requests)
    end

    private

    def save_pull_requests(pull_requests)
      return unless pull_request_store

      pull_request_store.write(pull_requests)

      NyaPr.logger.info(
        "Saved #{pull_requests.size} pull requests to #{pull_request_store.path}"
      )
    end
  end
end
