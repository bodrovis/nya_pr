# frozen_string_literal: true

module NyaPr
  module PullRequest
    class Finder
      include NyaPr::Request

      MAX_PULL_REQUESTS = 100
      MAX_PER_PAGE = 100

      attr_reader :client,
                  :repositories,
                  :limit,
                  :progress_enabled

      def initialize(
        client,
        repositories,
        limit: MAX_PULL_REQUESTS,
        progress_enabled: true
      )
        @client = client
        @repositories = repositories
        @limit = limit
        @progress_enabled = progress_enabled
      end

      def find
        NyaPr.logger.info(
          "Searching for up to #{limit} open pull requests " \
          "in #{repositories.size} repositories"
        )

        progress_bar = build_progress
        pull_requests = collect_pull_requests(progress_bar)

        progress_bar.finish

        NyaPr.logger.info(
          "Finished searching for pull requests: found #{pull_requests.size}"
        )

        pull_requests
      end

      private

      def collect_pull_requests(progress_bar)
        pull_requests = []

        repositories.each do |repository|
          break if pull_requests.size >= limit

          begin
            next unless repository.fetch('has_pull_requests', true)

            remaining = limit - pull_requests.size

            pull_requests.concat(
              pull_requests_for(repository, remaining)
            )
          ensure
            progress_bar.advance
          end
        end

        pull_requests
      end

      def pull_requests_for(repository, remaining)
        NyaPr.logger.debug(
          "Checking pull requests in #{repository.fetch('full_name')}"
        )

        pull_requests = []
        page = 1

        loop do
          per_page = page_size(remaining, pull_requests.size)
          batch = get_batch(repository, per_page, page)

          break if batch.empty?

          pull_requests.concat(
            batch.map do |pull_request|
              normalize(repository, pull_request)
            end
          )

          break if batch.size < per_page
          break if pull_requests.size >= remaining

          page += 1
        end

        pull_requests
      end

      def page_size(remaining, collected)
        [remaining - collected, MAX_PER_PAGE].min
      end

      def get_batch(repository, per_page, page)
        get(
          "/repos/#{repository.fetch('full_name')}/pulls",
          state: 'open',
          sort: 'updated',
          direction: 'desc',
          per_page: per_page,
          page: page
        )
      end

      def build_progress
        Progress.new(
          '🐾 Checking pull requests',
          total: repositories.size,
          enabled: progress_enabled && $stderr.tty?
        )
      end

      def normalize(repository, pull_request)
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
