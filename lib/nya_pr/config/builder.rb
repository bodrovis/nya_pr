# frozen_string_literal: true

module NyaPr
  module Config
    class Builder
      LOG_LEVELS = {
        'debug' => Logger::DEBUG,
        'info' => Logger::INFO,
        'warn' => Logger::WARN,
        'error' => Logger::ERROR,
        'fatal' => Logger::FATAL
      }.freeze

      BOOLEAN_KEYS = %i[
        refresh
        skip_archived
        skip_drafts
        progress
        save_pull_requests
      ].freeze

      def self.build(options, file_options: {})
        new(options, file_options).build
      end

      def initialize(options, file_options)
        @options = options
        @file_options = file_options
      end

      def build
        validate_keys!

        Global.new(
          **normalize(
            Defaults::OPTIONS.
              merge(file_options).
              merge(options.compact)
          )
        )
      end

      private

      attr_reader :options, :file_options

      def normalize(attributes)
        attributes.merge(
          username: normalize_username(attributes[:username]),
          owners: normalize_list(attributes[:owners]),
          exclude_repositories: normalize_repositories(
            attributes[:exclude_repositories]
          ),
          limit: normalize_positive_integer(attributes[:limit], :limit),
          workers: normalize_positive_integer(attributes[:workers], :workers),
          log_level: normalize_log_level(attributes[:log_level]),
          **normalize_booleans(attributes)
        )
      end

      def normalize_username(value)
        username = value.to_s.strip

        return username unless username.empty?

        raise NyaPr::Error, 'GitHub username is required'
      end

      def normalize_list(values)
        Array(values).
          flat_map { |value| value.to_s.split(',') }.
          map(&:strip).
          reject(&:empty?)
      end

      def normalize_repositories(values)
        normalize_list(values).
          map(&:downcase).
          uniq
      end

      def normalize_booleans(attributes)
        BOOLEAN_KEYS.to_h do |key|
          [key, normalize_boolean(attributes[key], key)]
        end
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
          raise NyaPr::Error, "Invalid log level: #{value}"
        end
      end

      def validate_keys!
        unknown = file_options.keys - Global.members

        return if unknown.empty?

        raise NyaPr::Error,
              "Unknown config option(s): #{unknown.join(', ')}"
      end
    end
  end
end
