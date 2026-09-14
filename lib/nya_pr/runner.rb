# frozen_string_literal: true

require 'dotenv'

module NyaPr
  class Runner
    attr_reader :config

    def initialize(config)
      @config = config
    end

    def run
      Dotenv.load
      configure_logger

      pull_requests = find_pull_requests

      pull_request_printer.print(pull_requests)
      save_pull_requests(pull_requests)
    end

    private

    def configure_logger
      NyaPr.logger.level = config.log_level
    end

    def target_repositories
      repository_collector.collect
    end

    def repository_config
      @repository_config ||= Repository::Config.from_app(config)
    end

    def pull_request_config
      @pull_request_config ||= PullRequest::Config.from_app(config)
    end

    def repository_paths
      @repository_paths ||= Repository::Paths.new(
        repository_config
      )
    end

    def pull_request_paths
      @pull_request_paths ||= PullRequest::Paths.new(
        pull_request_config
      )
    end

    def repository_store
      @repository_store ||= Repository::CsvStore.new(
        repository_paths.csv
      )
    end

    def pull_request_store
      @pull_request_store ||= PullRequest::CsvStore.new(
        pull_request_paths.csv
      )
    end

    def repository_collector
      @repository_collector ||= Repository::Collector.new(
        client,
        repository_store,
        repository_config
      )
    end

    def find_pull_requests
      PullRequest::Finder.
        new(
          client,
          target_repositories,
          pull_request_config
        ).
        find
    end

    def save_pull_requests(pull_requests)
      pull_request_store.write(pull_requests)

      NyaPr.logger.info(
        "Saved #{pull_requests.size} pull requests to #{pull_request_store.path}"
      )
    end

    def pull_request_printer
      @pull_request_printer ||= PullRequest::Printer.new
    end

    def client
      @client ||= Github::Client.new(token)
    end

    def token
      config.token || ENV.fetch('GITHUB_TOKEN') do
        raise NyaPr::Error,
              'GitHub token is required (--token or GITHUB_TOKEN)'
      end
    end
  end
end
