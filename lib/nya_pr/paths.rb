# frozen_string_literal: true

require 'fileutils'

module NyaPr
  class Paths
    DEFAULT_DATA_DIR = 'data'
    REPOSITORIES_FILENAME = 'repositories.csv'
    PULL_REQUESTS_FILENAME = 'pull_requests.csv'

    attr_reader :repositories_path, :pull_requests_dir

    def initialize(
      repositories_path: nil,
      pull_requests_dir: nil,
      timestamp: Time.now
    )
      @repositories_path = repositories_path
      @pull_requests_dir = pull_requests_dir
      @timestamp = timestamp
    end

    def repositories_csv
      path = Pathname.new(
        repositories_path || File.join(DEFAULT_DATA_DIR, REPOSITORIES_FILENAME)
      )

      prepare_parent(path)
      path.to_s
    end

    def pull_requests_csv
      path = pull_requests_run_dir.join(PULL_REQUESTS_FILENAME)

      FileUtils.mkdir_p(path.dirname)

      path.to_s
    end

    private

    attr_reader :timestamp

    def pull_requests_run_dir
      @pull_requests_run_dir ||= begin
        base = Pathname.new(pull_requests_dir || DEFAULT_DATA_DIR)

        base.join("pull_requests_#{formatted_timestamp}")
      end
    end

    def formatted_timestamp
      timestamp.strftime('%Y%m%d_%H%M%S')
    end

    def prepare_parent(path)
      FileUtils.mkdir_p(path.dirname)
    end
  end
end
