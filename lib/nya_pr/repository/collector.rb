# frozen_string_literal: true

module NyaPr
  module Repository
    class Collector
      attr_reader :client, :store, :config

      def initialize(client, store, config)
        @client = client
        @store = store
        @config = config
      end

      def collect
        return load_cached if use_cache?

        discover
      end

      private

      def load_cached
        NyaPr.logger.info("Loading repositories from #{store.path}")

        reject_archived(store.read).tap do |repositories|
          NyaPr.logger.info(
            "Loaded #{repositories.size} repositories from cache"
          )
        end
      end

      def discover
        NyaPr.logger.info(
          'Repository cache unavailable or refresh requested'
        )

        repositories = Finder.
                       new(client, config).
                       repositories_for

        repositories = filter_contributed(
          reject_archived(repositories)
        )

        store.write(repositories)

        NyaPr.logger.info(
          "Saved #{repositories.size} repositories to #{store.path}"
        )

        repositories
      end

      def filter_contributed(repositories)
        own, external = repositories.partition do |repository|
          repository_owner(repository).casecmp?(config.username)
        end

        own + Filter.new(client, config).contributed(external)
      end

      def reject_archived(repositories)
        return repositories unless config.skip_archived

        filtered = repositories.reject do |repository|
          repository['archived']
        end

        NyaPr.logger.info(
          "Skipped #{repositories.size - filtered.size} archived repositories"
        )

        filtered
      end

      def repository_owner(repository)
        repository.dig('owner', 'login').to_s
      end

      def use_cache?
        store.available? && !config.refresh
      end
    end
  end
end
