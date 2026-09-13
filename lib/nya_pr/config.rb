# frozen_string_literal: true

module NyaPr
  class Config < Data.define(
    :username,
    :owners,
    :token,
    :repositories_csv,
    :pull_requests_dir,
    :limit,
    :refresh,
    :skip_archived,
    :skip_drafts,
    :progress,
    :log_level
  )
    LOG_LEVELS = {
      'debug' => Logger::DEBUG,
      'info' => Logger::INFO,
      'warn' => Logger::WARN,
      'error' => Logger::ERROR,
      'fatal' => Logger::FATAL
    }.freeze

    class << self
      def from_options(options)
        username = options[:username].to_s
        validate_username!(username)

        new(
          username: username,
          owners: normalize_owners(options[:owners]),
          token: options[:token],
          repositories_csv: options[:repositories_csv],
          pull_requests_dir: options[:pull_requests_dir],
          limit: normalize_limit(options[:limit]),
          refresh: options[:refresh],
          skip_archived: options[:skip_archived],
          skip_drafts: options[:skip_drafts],
          progress: options[:progress],
          log_level: LOG_LEVELS.fetch(options[:log_level])
        )
      end

      private

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

      def validate_username!(username)
        return unless username.empty?

        raise NyaPr::Error, 'GitHub username is required'
      end
    end
  end
end
