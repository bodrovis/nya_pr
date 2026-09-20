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

      def self.build(options, file_options: {})
        new(options, file_options).build
      end

      def initialize(options, file_options)
        @options = options
        @file_options = file_options
      end

      def build
        result = Schema.call(
          normalize(
            Defaults::OPTIONS.
              merge(file_options).
              merge(options.compact)
          )
        )

        raise_config_error!(result) unless result.success?

        Global.new(
          **result.to_h, log_level: LOG_LEVELS.fetch(result[:log_level])
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
          )
        )
      end

      def normalize_username(value)
        value&.to_s&.strip
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

      def raise_config_error!(result)
        message = result.errors.to_h.
                  flat_map do |key, messages|
                    Array(messages).map do |error|
                      "#{key} #{error}"
                    end
                  end.
                  join(', ')

        raise NyaPr::Error, message
      end
    end
  end
end
