# frozen_string_literal: true

require 'dotenv'

module NyaPr
  class Runner
    def initialize(argv = ARGV)
      @argv = argv
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

    def options
      @options ||= Cli::Parser.new(@argv).parse
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
        skip_archived: options[:skip_archived]
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
          limit: options[:limit]
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
      ENV.fetch('GITHUB_TOKEN') do
        raise NyaPr::Error, 'GITHUB_TOKEN is not set'
      end
    end

    def username
      options.fetch(:username) do
        raise NyaPr::Error, 'GitHub username is required'
      end
    end

    def owners
      ([username] + options[:owners]).uniq
    end
  end
end
