# frozen_string_literal: true

require 'csv'

module NyaPr
  class PullRequestCsv
    HEADERS = %w[
      repository
      number
      title
      author
      draft
      created_at
      updated_at
      html_url
    ].freeze

    attr_reader :path

    def initialize(path)
      @path = path
    end

    def write(pull_requests)
      CSV.open(path, 'w', write_headers: true, headers: HEADERS) do |csv|
        pull_requests.each do |pull_request|
          csv << HEADERS.map { |header| pull_request[header] }
        end
      end
    end
  end
end
