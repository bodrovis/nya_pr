# frozen_string_literal: true

module NyaPr
  module Config
    class Global < Data.define(
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
      :log_level,
      :workers
    )
      LOG_LEVELS = {
        'debug' => Logger::DEBUG,
        'info' => Logger::INFO,
        'warn' => Logger::WARN,
        'error' => Logger::ERROR,
        'fatal' => Logger::FATAL
      }.freeze

      DEFAULTS = {
        owners: [],
        token: nil,
        repositories_csv: nil,
        pull_requests_dir: nil,
        limit: PullRequest::Config::DEFAULT_LIMIT,
        refresh: false,
        skip_archived: false,
        skip_drafts: false,
        progress: true,
        log_level: 'info',
        workers: Repository::Config::DEFAULT_WORKERS
      }.freeze

      BOOLEAN_KEYS = %i[
        refresh
        skip_archived
        skip_drafts
        progress
      ].freeze

      class << self
        def from_options(options, file_options: {})
          validate_keys!(file_options)

          attributes = DEFAULTS.
                       merge(file_options).
                       merge(options.compact)

          build(attributes)
        end

        private

        def build(attributes)
          normalized = attributes.merge(
            username: normalize_username(attributes[:username]),
            owners: normalize_owners(attributes[:owners]),
            limit: normalize_positive_integer(attributes[:limit], :limit),
            workers: normalize_positive_integer(attributes[:workers], :workers),
            log_level: normalize_log_level(attributes[:log_level]),
            **normalize_booleans(attributes)
          )

          new(**normalized)
        end

        def normalize_username(value)
          username = value.to_s.strip

          validate_username!(username)

          username
        end

        def normalize_booleans(attributes)
          BOOLEAN_KEYS.to_h do |key|
            [key, normalize_boolean(attributes[key], key)]
          end
        end

        def validate_keys!(options)
          unknown = options.keys - members

          return if unknown.empty?

          raise NyaPr::Error,
                "Unknown config option(s): #{unknown.join(', ')}"
        end

        def normalize_owners(owners)
          Array(owners).
            flat_map { |owner| owner.to_s.split(',') }.
            map(&:strip).
            reject(&:empty?)
        end

        def normalize_positive_integer(value, name)
          number = Integer(value)

          return number if number.positive?

          raise NyaPr::Error, "#{name} must be greater than 0"
        rescue ArgumentError, TypeError
          raise NyaPr::Error, "#{name} must be a positive integer"
        end

        def normalize_boolean(value, name)
          return value if [true, false].include?(value)

          raise NyaPr::Error, "#{name} must be true or false"
        end

        def normalize_log_level(value)
          LOG_LEVELS.fetch(value.to_s) do
            raise NyaPr::Error,
                  "Invalid log level: #{value}"
          end
        end

        def validate_username!(username)
          return unless username.empty?

          raise NyaPr::Error, 'GitHub username is required'
        end
      end
    end
  end
end
