# frozen_string_literal: true

require 'faraday'
require 'faraday/gzip'

module NyaPr
  module Github
    module Connection
      API_URL = 'https://api.github.com'
      API_VERSION = '2026-03-10'

      def connection(client)
        Faraday.new(connection_options(client)) do |faraday|
          faraday.request :gzip
          faraday.adapter Faraday.default_adapter
        end
      end

      private

      def connection_options(client)
        {
          url: API_URL,
          headers: {
            accept: 'application/vnd.github+json',
            user_agent: "nya_pr gem/#{NyaPr::VERSION}",
            authorization: "Bearer #{client.token}",
            'X-GitHub-Api-Version': client.options.fetch(:api_version, API_VERSION)
          },
          request: {
            timeout: client.options.fetch(:timeout, 60),
            open_timeout: client.options.fetch(:open_timeout, 10)
          }
        }
      end
    end
  end
end
