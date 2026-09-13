# frozen_string_literal: true

module NyaPr
  module Cli
    class Command < Dry::CLI::Command
      LOG_LEVELS = {
        'debug' => Logger::DEBUG,
        'info' => Logger::INFO,
        'warn' => Logger::WARN,
        'error' => Logger::ERROR,
        'fatal' => Logger::FATAL
      }.freeze

      desc 'Collect open GitHub pull requests'

      option :username,
             aliases: ['-u', '--user'],
             desc: 'GitHub username'

      option :owners,
             aliases: ['-o'],
             type: :array,
             default: [],
             desc: 'Repository owners'

      option :token,
             desc: 'GitHub token'

      option :repositories_csv,
             desc: 'Repository cache CSV path'

      option :pull_requests_dir,
             desc: 'Directory for pull request runs'

      option :limit,
             aliases: ['-l'],
             default: PullRequest::Finder::MAX_PULL_REQUESTS,
             desc: 'Maximum number of pull requests'

      option :refresh,
             aliases: ['-r'],
             type: :boolean,
             default: false,
             desc: 'Refresh repositories from GitHub'

      option :skip_archived,
             type: :boolean,
             default: false,
             desc: 'Skip archived repositories'

      option :progress,
             type: :boolean,
             default: true,
             desc: 'Show progress bars'

      option :log_level,
             values: LOG_LEVELS.keys,
             default: 'info',
             desc: 'Log level'

      option :version,
             aliases: ['-v'],
             type: :flag,
             desc: 'Show version'

      def call(version: false, **options)
        if version
          puts NyaPr::VERSION
          return
        end

        normalize_options!(options)
        validate_username!(options)

        Runner.new(options).run
      end

      private

      def normalize_options!(options)
        options[:owners] = normalize_owners(options[:owners])
        options[:limit] = normalize_limit(options[:limit])
        options[:log_level] = LOG_LEVELS.fetch(options[:log_level])
      end

      def normalize_owners(owners)
        Array(owners).
          flat_map { |owner| owner.split(',') }.
          map(&:strip).
          reject(&:empty?)
      end

      def normalize_limit(value)
        limit = Integer(value)

        return limit if limit.positive?

        raise NyaPr::Error, 'limit must be greater than 0'
      rescue ArgumentError, TypeError
        raise NyaPr::Error, 'limit must be a positive integer'
      end

      def validate_username!(options)
        return unless options[:username].to_s.empty?

        raise NyaPr::Error, 'GitHub username is required'
      end
    end
  end
end
