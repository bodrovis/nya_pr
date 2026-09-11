# frozen_string_literal: true

require 'optparse'

module NyaPr
  module Cli
    class Parser
      DEFAULT_REPOSITORIES_CSV = 'repositories.csv'
      DEFAULT_PULL_REQUESTS_CSV = 'pull_requests.csv'

      LOG_LEVELS = {
        'debug' => Logger::DEBUG,
        'info' => Logger::INFO,
        'warn' => Logger::WARN,
        'error' => Logger::ERROR,
        'fatal' => Logger::FATAL
      }.freeze

      attr_reader :argv

      def initialize(argv = ARGV)
        @argv = argv
      end

      def parse
        options = default_options

        parser(options).parse!(argv)

        options
      end

      private

      def default_options
        {
          owners: [],
          csv: DEFAULT_REPOSITORIES_CSV,
          pr_csv: DEFAULT_PULL_REQUESTS_CSV,
          refresh: false,
          skip_archived: false,
          log_level: 'info',
          limit: PullRequest::Finder::MAX_PULL_REQUESTS
        }
      end

      def parser(options)
        OptionParser.new do |parser|
          parser.banner = 'Usage: nya-pr --user USERNAME [options]'

          username_option(parser, options)
          owners_option(parser, options)
          csv_option(parser, options)
          pr_csv_option(parser, options)
          limit_option(parser, options)
          refresh_option(parser, options)
          skip_archived_option(parser, options)
          log_level_option(parser, options)
        end
      end

      def username_option(parser, options)
        parser.on('-u', '--user USERNAME', 'GitHub username') do |value|
          options[:username] = value
        end
      end

      def owners_option(parser, options)
        parser.on('-o', '--owners LIST', 'Repository owners') do |value|
          options[:owners] = parse_owners(value)
        end
      end

      def csv_option(parser, options)
        parser.on('--csv FILE', 'Repository CSV file') do |value|
          options[:csv] = value
        end
      end

      def pr_csv_option(parser, options)
        parser.on('--pr-csv FILE', 'Pull requests CSV file') do |value|
          options[:pr_csv] = value
        end
      end

      def limit_option(parser, options)
        parser.on(
          '-l',
          '--limit N',
          Integer,
          'Maximum number of pull requests'
        ) do |value|
          unless value.positive?
            raise OptionParser::InvalidArgument,
                  'limit must be greater than 0'
          end

          options[:limit] = value
        end
      end

      def refresh_option(parser, options)
        parser.on('-r', '--refresh', 'Refresh repositories from GitHub') do
          options[:refresh] = true
        end
      end

      def skip_archived_option(parser, options)
        parser.on('--skip-archived', 'Skip archived repositories') do
          options[:skip_archived] = true
        end
      end

      def log_level_option(parser, options)
        parser.on(
          '--log-level LEVEL',
          LOG_LEVELS.keys,
          "Log level: #{LOG_LEVELS.keys.join(', ')}"
        ) do |value|
          options[:log_level] = value
        end
      end

      def parse_owners(value)
        value.
          split(',').
          map(&:strip).
          reject(&:empty?)
      end
    end
  end
end
