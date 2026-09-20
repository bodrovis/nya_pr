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

        repositories = store.read
        repositories = reject_archived(repositories)
        repositories = reject_excluded(repositories)

        repositories.tap do |result|
          NyaPr.logger.info(
            "Loaded #{result.size} repositories from cache"
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

        repositories = reject_archived(repositories)
        repositories = reject_excluded(repositories)
        repositories = filter_contributed(repositories)

        store.write(repositories)

        NyaPr.logger.info(
          "Selected #{repositories.size} repositories for pull request scanning"
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

      def reject_excluded(repositories)
        return repositories if config.exclude_repositories.empty?

        filtered = repositories.reject do |repository|
          config.exclude_repositories.include?(
            repository.fetch('full_name').downcase
          )
        end

        NyaPr.logger.info(
          "Skipped #{repositories.size - filtered.size} excluded repositories"
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
