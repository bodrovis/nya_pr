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

    def paths
      @paths ||= Paths.new(
        repositories_path: config.repositories_csv,
        pull_requests_dir: config.pull_requests_dir
      )
    end

    def configure_logger
      NyaPr.logger.level = config.log_level
    end

    def target_repositories
      repository_collector.collect
    end

    def repository_collector
      @repository_collector ||= Repository::Collector.new(
        client,
        repository_store,
        repository_config
      )
    end

    def repository_config
      @repository_config ||= Repository::Config.from_app(config)
    end

    def save_pull_requests(pull_requests)
      pull_request_store.write(pull_requests)

      NyaPr.logger.info(
        "Saved #{pull_requests.size} pull requests to #{pull_request_store.path}"
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

    def pull_request_config
      @pull_request_config ||= PullRequest::Config.from_app(config)
    end

    def repository_store
      @repository_store ||= Repository::CsvStore.new(paths.repositories_csv)
    end

    def pull_request_store
      @pull_request_store ||= PullRequest::CsvStore.new(paths.pull_requests_csv)
    end

    def pull_request_printer
      @pull_request_printer ||= PullRequest::Printer.new
    end

    def client
      @client ||= Client.new(token)
    end

    def token
      config.token || ENV.fetch('GITHUB_TOKEN') do
        raise NyaPr::Error,
              'GitHub token is required (--token or GITHUB_TOKEN)'
      end
    end
  end
end
