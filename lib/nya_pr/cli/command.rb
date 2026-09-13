# frozen_string_literal: true

module NyaPr
  module Cli
    class Command < Dry::CLI::Command
      desc 'Collect open GitHub pull requests'

      option :username,
             aliases: ['-u', '--user'],
             desc: 'GitHub username'

      option :owners,
             aliases: ['-o'],
             type: :array,
             default: [],
             desc: 'Repository owners'

      option :token,
             desc: 'GitHub token'

      option :repositories_csv,
             desc: 'Repository cache CSV path'

      option :pull_requests_dir,
             desc: 'Directory for pull request runs'

      option :limit,
             aliases: ['-l'],
             default: PullRequest::Config::DEFAULT_LIMIT,
             desc: 'Maximum number of pull requests'

      option :refresh,
             aliases: ['-r'],
             type: :boolean,
             default: false,
             desc: 'Refresh repositories from GitHub'

      option :skip_archived,
             type: :boolean,
             default: false,
             desc: 'Skip archived repositories'

      option :skip_drafts,
             type: :boolean,
             default: false,
             desc: 'Ignore draft pull requests'

      option :progress,
             type: :boolean,
             default: true,
             desc: 'Show progress bars'

      option :log_level,
             values: Config::LOG_LEVELS.keys,
             default: 'info',
             desc: 'Log level'

      option :version,
             aliases: ['-v'],
             type: :flag,
             desc: 'Show version'

      def call(version: false, **options)
        if version
          puts NyaPr::VERSION
          return
        end

        Runner.new(Config.from_options(options)).run
      end
    end
  end
end
