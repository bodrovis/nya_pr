# frozen_string_literal: true

require 'dotenv'
require 'optparse'

module NyaPr
  class Runner
    DEFAULT_REPOSITORIES_CSV = 'repositories.csv'
    DEFAULT_PULL_REQUESTS_CSV = 'pull_requests.csv'
    LOG_LEVELS = {
      'debug' => Logger::DEBUG,
      'info' => Logger::INFO,
      'warn' => Logger::WARN,
      'error' => Logger::ERROR,
      'fatal' => Logger::FATAL
    }.freeze

    def initialize(argv = ARGV)
      @argv = argv
    end

    def run
      Dotenv.load
      configure_logger

      pull_requests = find_pull_requests

      print_pull_requests(pull_requests)
      pull_request_csv.write(pull_requests)
    end

    private

    def configure_logger
      NyaPr.logger.level = LOG_LEVELS.fetch(options[:log_level])
    end

    def repositories
      if use_cached_repositories?
        NyaPr.logger.info("Loading repositories from #{options[:csv]}")

        return reject_archived(repository_csv.read).tap do |repositories|
          NyaPr.logger.info(
            "Loaded #{repositories.size} repositories from cache"
          )
        end
      end

      NyaPr.logger.info('Repository cache unavailable or refresh requested')

      fetch_repositories.tap do |repositories|
        repository_csv.write(repositories)

        NyaPr.logger.info(
          "Saved #{repositories.size} repositories to #{options[:csv]}"
        )
      end
    end

    def fetch_repositories
      repositories = RepositoryFinder.
                     new(client, username).
                     repositories_for(owners)

      repositories = reject_archived(repositories)

      filter_repositories(repositories)
    end

    def use_cached_repositories?
      repository_csv.available? && !options[:refresh]
    end

    def reject_archived(repositories)
      return repositories unless options[:skip_archived]

      non_archived_repos = repositories.reject do |repository|
        repository['archived']
      end

      non_archived_repos.tap do |filtered|
        skipped = repositories.size - filtered.size

        NyaPr.logger.info("Skipped #{skipped} archived repositories")
      end
    end

    def filter_repositories(repositories)
      own, external = repositories.partition do |repository|
        repository_owner(repository).casecmp?(username)
      end

      own + repository_filter.contributed(external)
    end

    def repository_filter
      @repository_filter ||= RepositoryFilter.new(client, username)
    end

    def repository_owner(repository)
      repository.dig('owner', 'login').to_s
    end

    def find_pull_requests
      PullRequestFinder.
        new(client, repositories, limit: options[:limit]).
        find
    end

    def repository_csv
      @repository_csv ||= RepositoryCsv.new(options[:csv])
    end

    def pull_request_csv
      @pull_request_csv ||= PullRequestCsv.new(options[:pr_csv])
    end

    def client
      @client ||= Client.new(token, debug: options[:debug])
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

    def options
      @options ||= parse_options
    end

    def parse_options
      result = default_options

      option_parser(result).parse!(@argv)

      result
    end

    def default_options
      {
        owners: [],
        csv: DEFAULT_REPOSITORIES_CSV,
        pr_csv: DEFAULT_PULL_REQUESTS_CSV,
        refresh: false,
        skip_archived: false,
        log_level: 'info',
        limit: PullRequestFinder::MAX_PULL_REQUESTS
      }
    end

    def option_parser(result)
      OptionParser.new do |parser|
        parser.banner = 'Usage: nya-pr --user USERNAME [options]'

        username_option(parser, result)
        owners_option(parser, result)
        csv_option(parser, result)
        pr_csv_option(parser, result)
        refresh_option(parser, result)
        skip_archived_option(parser, result)
        log_level_option(parser, result)
        limit_option(parser, result)
      end
    end

    def username_option(parser, result)
      parser.on('-u', '--user USERNAME', 'GitHub username') do |value|
        result[:username] = value
      end
    end

    def limit_option(parser, result)
      parser.on(
        '-l',
        '--limit N',
        Integer,
        'Maximum number of pull requests'
      ) do |value|
        raise OptionParser::InvalidArgument, 'limit must be greater than 0' unless value.positive?

        result[:limit] = value
      end
    end

    def log_level_option(parser, result)
      parser.on(
        '--log-level LEVEL',
        LOG_LEVELS.keys,
        "Log level: #{LOG_LEVELS.keys.join(', ')}"
      ) do |value|
        result[:log_level] = value
      end
    end

    def owners_option(parser, result)
      parser.on('-o', '--owners LIST', 'Repository owners') do |value|
        result[:owners] = parse_owners(value)
      end
    end

    def skip_archived_option(parser, result)
      parser.on('--skip-archived', 'Skip archived repositories') do
        result[:skip_archived] = true
      end
    end

    def csv_option(parser, result)
      parser.on('--csv FILE', 'Repository CSV file') do |value|
        result[:csv] = value
      end
    end

    def pr_csv_option(parser, result)
      parser.on('--pr-csv FILE', 'Pull requests CSV file') do |value|
        result[:pr_csv] = value
      end
    end

    def refresh_option(parser, result)
      parser.on('-r', '--refresh', 'Refresh repositories from GitHub') do
        result[:refresh] = true
      end
    end

    def parse_owners(value)
      value.split(',').map(&:strip).reject(&:empty?)
    end

    def print_pull_requests(pull_requests)
      pull_requests.
        group_by { |pull_request| pull_request['repository'] }.
        each do |repository, repository_pull_requests|
          print_repository(repository, repository_pull_requests)
        end
    end

    def print_repository(repository, pull_requests)
      puts
      puts repository
      puts '-' * repository.length

      pull_requests.each do |pull_request|
        puts format_pull_request(pull_request)
        puts
      end
    end

    def format_pull_request(pull_request)
      draft = pull_request['draft'] ? ' [DRAFT]' : ''

      <<~OUTPUT.chomp
        ##{pull_request['number']}#{draft} #{pull_request['title']}
          Author: @#{pull_request['author']}
          #{pull_request['html_url']}
      OUTPUT
    end
  end
end
