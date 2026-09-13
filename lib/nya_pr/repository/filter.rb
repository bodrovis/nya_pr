# frozen_string_literal: true

module NyaPr
  module Repository
    class Filter
      include NyaPr::Request

      attr_reader :client, :config

      def initialize(client, config)
        @client = client
        @config = config
      end

      def contributed(repositories)
        log_start(repositories)

        progress_bar = build_progress(repositories)
        result = process_repositories(repositories, progress_bar)

        progress_bar.finish

        log_result(result)
        result
      end

      private

      def username
        config.username
      end

      def workers
        config.workers
      end

      def progress_enabled
        config.progress_enabled
      end

      def log_start(repositories)
        NyaPr.logger.info(
          "Checking contributions in #{repositories.size} repositories " \
          "using #{workers} workers"
        )
      end

      def build_progress(repositories)
        Progress.new(
          '🐈 Checking repositories',
          total: repositories.size,
          enabled: progress_enabled && $stderr.tty?
        )
      end

      def process_repositories(repositories, progress_bar)
        queue = build_queue(repositories)
        result = Array.new(repositories.size)

        build_workers(queue, result, progress_bar).
          each(&:value)

        result.compact
      end

      def build_workers(queue, result, progress_bar)
        Array.new(workers) do
          Thread.new do
            process_queue(queue, result, progress_bar)
          end
        end
      end

      def log_result(result)
        NyaPr.logger.info(
          "Finished contribution check: #{result.size} repositories matched"
        )
      end

      def build_queue(repositories)
        Queue.new.tap do |queue|
          repositories.each_with_index do |repository, index|
            queue << [index, repository]
          end
        end
      end

      def process_queue(queue, result, progress_bar)
        loop do
          index, repository = queue.pop(true)

          process_repository(repository, index, result)
          progress_bar.advance
        rescue ThreadError
          break
        end
      end

      def process_repository(repository, index, result)
        return unless contributed_to?(repository)

        result[index] = repository

        NyaPr.logger.debug(
          "Found contributions in #{repository.fetch('full_name')}"
        )
      end

      def contributed_to?(repository)
        commits = get(
          "/repos/#{repository.fetch('full_name')}/commits",
          author: username,
          per_page: 1
        )

        commits.any?
      rescue NyaPr::Error => e
        raise unless e.status == 409

        NyaPr.logger.debug(
          "Skipping empty repository #{repository.fetch('full_name')}"
        )

        false
      end
    end
  end
end
