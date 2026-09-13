# frozen_string_literal: true

module NyaPr
  module Repository
    class Filter
      include NyaPr::Request

      DEFAULT_WORKERS = 10

      attr_reader :client, :username, :workers, :progress_enabled

      def initialize(client, username, workers: DEFAULT_WORKERS, progress_enabled: true)
        @client = client
        @username = username
        @workers = workers
        @progress_enabled = progress_enabled
      end

      def contributed(repositories)
        NyaPr.logger.info(
          "Checking contributions in #{repositories.size} repositories " \
          "using #{workers} workers"
        )

        NyaPr.logger.debug(
          "Progress enabled=#{progress_enabled}, tty=#{$stderr.tty?}, total=#{repositories.size}"
        )
        progress_bar = Progress.new(
          '🐈 Checking repositories',
          total: repositories.size,
          enabled: progress_enabled && $stderr.tty?
        )

        queue = build_queue(repositories)
        result = Array.new(repositories.size)

        threads = Array.new(workers) do
          Thread.new do
            process_queue(queue, result, progress_bar)
          end
        end

        threads.each(&:value)
        progress_bar.finish

        result.compact.tap do |filtered|
          NyaPr.logger.info(
            "Finished contribution check: #{filtered.size} repositories matched"
          )
        end
      end

      private

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

          if contributed_to?(repository)
            result[index] = repository

            NyaPr.logger.debug(
              "Found contributions in #{repository.fetch('full_name')}"
            )
          end

          progress_bar.advance
        rescue ThreadError
          break
        end
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
