# frozen_string_literal: true

module NyaPr
  module PullRequest
    class Finder
      include NyaPr::Github::Request

      MAX_PER_PAGE = 100

      attr_reader :client,
                  :config,
                  :filter

      def initialize(client, config, filter: nil)
        @client = client
        @config = config
        @filter = filter || Filter.new(config)
      end

      def find(repositories)
        NyaPr.logger.info(
          "Searching for up to #{config.limit} open pull requests " \
          "in #{repositories.size} repositories"
        )

        progress_bar = build_progress(repositories.size)

        pull_requests = collect_pull_requests(
          repositories,
          progress_bar
        )

        progress_bar.finish

        NyaPr.logger.info(
          "Finished searching for pull requests: found #{pull_requests.size}"
        )

        pull_requests
      end

      private

      def collect_pull_requests(repositories, progress_bar)
        pull_requests = []

        repositories.each_slice(config.workers) do |repositories_batch|
          remaining = config.limit - pull_requests.size
          break unless remaining.positive?

          results = process_batch(
            repositories_batch,
            remaining,
            progress_bar
          )

          append_results(
            pull_requests,
            results
          )
        end

        pull_requests
      end

      def process_batch(repositories, limit, progress_bar)
        threads = repositories.map do |repository|
          Thread.new do
            Thread.current.report_on_exception = false

            process_repository(
              repository,
              limit,
              progress_bar
            )
          end
        end

        threads.map(&:value)
      end

      def append_results(pull_requests, results)
        results.each do |repository_pull_requests|
          remaining = config.limit - pull_requests.size
          break unless remaining.positive?

          pull_requests.concat(
            repository_pull_requests.first(remaining)
          )
        end
      end

      def process_repository(repository, limit, progress_bar)
        return [] unless pull_requests_enabled?(repository)

        pull_requests_for(repository, limit)
      ensure
        progress_bar.advance
      end

      def pull_requests_enabled?(repository)
        repository.fetch('has_pull_requests', true)
      end

      def pull_requests_for(repository, remaining)
        NyaPr.logger.debug(
          "Checking pull requests in #{repository.fetch('full_name')}"
        )

        pull_requests = []
        per_page = [remaining, MAX_PER_PAGE].min

        each_batch(repository, per_page) do |batch|
          append_matches(
            pull_requests,
            repository,
            batch,
            remaining
          )

          break if pull_requests.size >= remaining
        end

        pull_requests
      end

      def each_batch(repository, per_page)
        page = 1

        loop do
          batch = get_batch(repository, per_page, page)

          break if batch.empty?

          yield batch

          break if batch.size < per_page

          page += 1
        end
      end

      def append_matches(pull_requests, repository, batch, limit)
        needed = limit - pull_requests.size

        pull_requests.concat(
          filter_batch(repository, batch).first(needed)
        )
      end

      def filter_batch(repository, batch)
        batch.
          map { |pull_request| normalize(repository, pull_request) }.
          grep(filter)
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

      def build_progress(total)
        Progress.new(
          '🐾 Checking pull requests',
          total: total,
          enabled: config.progress_enabled && $stderr.tty?
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
