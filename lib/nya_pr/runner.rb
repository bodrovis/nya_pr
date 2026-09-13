# frozen_string_literal: true

require 'dotenv'

module NyaPr
  class Runner
    attr_reader :options

    def initialize(options)
      @options = options
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
        repositories_path: options[:repositories_csv],
        pull_requests_dir: options[:pull_requests_dir]
      )
    end

    def configure_logger
      NyaPr.logger.level = options[:log_level]
    end

    def target_repositories
      repository_collector.collect
    end

    def repository_collector
      @repository_collector ||= Repository::Collector.new(
        client,
        username,
        owners,
        repository_store,
        refresh: options[:refresh],
        skip_archived: options[:skip_archived],
        progress: options[:progress]
      )
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
          limit: options[:limit],
          progress_enabled: options[:progress]
        ).
        find
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
      options[:token] || ENV.fetch('GITHUB_TOKEN') do
        raise NyaPr::Error, 'GitHub token is required (--token or GITHUB_TOKEN)'
      end
    end

    def username
      options[:username]
    end

    def owners
      ([username] + options[:owners]).uniq
    end
  end
end
