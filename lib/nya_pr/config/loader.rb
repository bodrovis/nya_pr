# frozen_string_literal: true

require 'yaml'

module NyaPr
  module Config
    class Loader
      DEFAULT_PATH = '.nya-pr.yml'

      def self.load(path = nil)
        new(path).load
      end

      attr_reader :path

      def initialize(path = nil)
        @explicit_path = !path.nil?
        @path = Pathname.new(path || DEFAULT_PATH)
      end

      def load
        unless path.exist?
          return {} unless explicit_path?

          raise NyaPr::Error, "Config file not found: #{path}"
        end

        parse
      rescue Psych::SyntaxError => e
        raise NyaPr::Error,
              "Invalid YAML in #{path}: #{e.problem}"
      rescue Errno::EACCES, Errno::ENOENT => e
        raise NyaPr::Error,
              "Cannot read config file #{path}: #{e.message}"
      end

      private

      def explicit_path?
        @explicit_path
      end

      def parse
        data = YAML.safe_load_file(
          path.to_s,
          aliases: false
        )

        return {} if data.nil?

        unless data.is_a?(Hash)
          raise NyaPr::Error,
                "Config file must contain a mapping: #{path}"
        end

        symbolize_keys(data)
      end

      def symbolize_keys(data)
        data.to_h do |key, value|
          unless key.is_a?(String) || key.is_a?(Symbol)
            raise NyaPr::Error,
                  "Invalid config key: #{key.inspect}"
          end

          [key.to_sym, value]
        end
      end
    end
  end
end
