# frozen_string_literal: true

module NyaPr
  module Repository
    class Finder
      include NyaPr::Github::Request

      attr_reader :client, :config

      def initialize(client, config)
        @client = client
        @config = config
      end

      def repositories_for
        NyaPr.logger.info(
          "Starting repository collection for #{owners.size} owners"
        )

        repositories = owners.flat_map do |owner|
          collect_repositories_for(owner)
        end

        NyaPr.logger.info(
          "Finished repository collection: #{repositories.size} repositories found"
        )

        repositories
      end

      private

      def owners
        config.owners
      end

      def username
        config.username
      end

      def collect_repositories_for(owner)
        NyaPr.logger.info("Collecting repositories for #{owner}")

        repositories_for_owner(owner).tap do |repositories|
          NyaPr.logger.info(
            "Collected #{repositories.size} repositories for #{owner}"
          )
        end
      end

      def repositories_for_owner(owner)
        return own_repositories if owner.casecmp?(username)

        type = owner_type(owner)

        NyaPr.logger.debug("#{owner} is a GitHub #{type}")

        case type
        when 'Organization'
          organization_repositories(owner)
        when 'User'
          user_repositories(owner)
        else
          raise NyaPr::Error, "Unsupported GitHub owner type: #{owner}"
        end
      end

      def owner_type(owner)
        get("/users/#{owner}").fetch('type')
      end

      def own_repositories
        paginate(
          '/user/repos',
          affiliation: 'owner',
          visibility: 'all'
        )
      end

      def organization_repositories(owner)
        paginate(
          "/orgs/#{owner}/repos",
          type: 'all'
        )
      end

      def user_repositories(owner)
        paginate(
          "/users/#{owner}/repos",
          type: 'owner'
        )
      end
    end
  end
end
