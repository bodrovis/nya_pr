# frozen_string_literal: true

require 'fileutils'

module NyaPr
  module Repository
    class Paths
      DEFAULT_PATH = 'data/repositories.csv'

      attr_reader :config

      def initialize(config)
        @config = config
      end

      def csv
        path = Pathname.new(
          config.repositories_csv || DEFAULT_PATH
        )

        FileUtils.mkdir_p(path.dirname)

        path.to_s
      end
    end
  end
end
