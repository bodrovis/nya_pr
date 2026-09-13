# frozen_string_literal: true

module NyaPr
  module Repository
    class CsvStore
      HEADERS = %w[
        full_name
        html_url
        visibility
        private
        archived
        has_pull_requests
      ].freeze

      attr_reader :path

      def initialize(path)
        @path = path
      end

      def available?
        return false unless File.file?(path)

        CSV.open(path, headers: true) { |csv| !csv.first.nil? }
      end

      def read
        CSV.read(path, headers: true).map do |row|
          {
            'full_name' => row['full_name'],
            'html_url' => row['html_url'],
            'visibility' => row['visibility'],
            'private' => row['private'] == 'true',
            'archived' => row['archived'] == 'true',
            'has_pull_requests' => row['has_pull_requests'] != 'false'
          }
        end
      end

      def write(repositories)
        CSV.open(path, 'w', write_headers: true, headers: HEADERS) do |csv|
          repositories.each do |repository|
            csv << HEADERS.map { |header| repository[header] }
          end
        end
      end
    end
  end
end
