# frozen_string_literal: true

module NyaPr
  class RunnerFactory
    def self.build(config)
      new(config).build
    end

    def initialize(config)
      @config = config
    end

    def build
      Runner.new(
        repository_collector: repository_collector,
        pull_request_finder: pull_request_finder,
        pull_request_printer: PullRequest::Printer.new,
        pull_request_store: pull_request_store
      )
    end

    private

    attr_reader :config
    
    def repository_config
      @repository_config ||= Repository::Config.from_app(config)
    end

    def pull_request_config
      @pull_request_config ||= PullRequest::Config.from_app(config)
    end

    def repository_store
      @repository_store ||= Repository::CsvStore.new(
        Repository::Paths.new(repository_config).csv
      )
    end

    def repository_collector
      @repository_collector ||= Repository::Collector.new(
        client,
        repository_store,
        repository_config
      )
    end

    def pull_request_finder
      @pull_request_finder ||= PullRequest::Finder.new(
        client,
        pull_request_config
      )
    end

    def pull_request_store
      return unless config.save_pull_requests

      @pull_request_store ||= PullRequest::CsvStore.new(
        PullRequest::Paths.new(pull_request_config).csv
      )
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
