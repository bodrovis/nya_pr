# frozen_string_literal: true

require 'optparse'

module NyaPr
  module Cli
    class Parser
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
          repositories_csv: nil,
          pull_requests_dir: nil,
          refresh: false,
          skip_archived: false,
          log_level: Logger::INFO,
          limit: PullRequest::Finder::MAX_PULL_REQUESTS,
          progress: true
        }
      end

      def parser(options)
        OptionParser.new do |parser|
          parser.banner = 'Usage: nya-pr --user USERNAME [options]'

          username_option(parser, options)
          owners_option(parser, options)
          repositories_csv_option(parser, options)
          pull_requests_dir_option(parser, options)
          limit_option(parser, options)
          refresh_option(parser, options)
          skip_archived_option(parser, options)
          progress_option(parser, options)
          log_level_option(parser, options)
        end
      end

      def progress_option(parser, options)
        parser.on(
          '--[no-]progress',
          'Show progress bars'
        ) do |value|
          options[:progress] = value
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

      def repositories_csv_option(parser, options)
        parser.on(
          '--repositories-csv PATH',
          'Repository cache CSV path'
        ) do |value|
          options[:repositories_csv] = value
        end
      end

      def pull_requests_dir_option(parser, options)
        parser.on(
          '--pull-requests-dir PATH',
          'Directory for pull request runs'
        ) do |value|
          options[:pull_requests_dir] = value
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
          options[:log_level] = LOG_LEVELS.fetch(value)
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
