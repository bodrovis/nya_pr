# frozen_string_literal: true

module NyaPr
  module PullRequest
    class Finder
      include NyaPr::Request

      MAX_PULL_REQUESTS = 100

      attr_reader :client, :repositories, :limit

      def initialize(client, repositories, limit: MAX_PULL_REQUESTS)
        @client = client
        @repositories = repositories
        @limit = limit
      end

      def find
        NyaPr.logger.info(
          "Searching for up to #{limit} open pull requests in #{repositories.size} repositories"
        )

        pull_requests = collect_pull_requests

        NyaPr.logger.info(
          "Finished searching for pull requests: found #{pull_requests.size}"
        )

        pull_requests
      end

      private

      def collect_pull_requests
        repositories.each_with_object([]) do |repository, pull_requests|
          break pull_requests if pull_requests.size >= limit

          pull_requests.concat(
            pull_requests_for(repository, limit - pull_requests.size)
          )
        end
      end

      def pull_requests_for(repository, remaining)
        return [] unless pull_requests_enabled?(repository)

        name = repository.fetch('full_name')

        NyaPr.logger.debug("Searching for pull requests in #{name}")

        get(
          "/repos/#{name}/pulls",
          state: 'open',
          sort: 'updated',
          direction: 'desc',
          per_page: remaining
        ).map do |pull_request|
          normalize(pull_request, repository)
        end
      end

      def pull_requests_enabled?(repository)
        return true if repository.fetch('has_pull_requests', true)

        NyaPr.logger.debug(
          "Skipping #{repository.fetch('full_name')}: pull requests are disabled"
        )

        false
      end

      def normalize(pull_request, repository)
        {
          'repository' => repository.fetch('full_name'),
          'number' => pull_request.fetch('number'),
          'title' => pull_request.fetch('title'),
          'author' => pull_request.dig('user', 'login'),
          'draft' => pull_request.fetch('draft', false),
          'created_at' => pull_request['created_at'],
          'updated_at' => pull_request['updated_at'],
          'html_url' => pull_request.fetch('html_url')
        }
      end
    end
  end
end
