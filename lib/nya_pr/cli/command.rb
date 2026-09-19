# frozen_string_literal: true

module NyaPr
  module Cli
    class Command < Dry::CLI::Command
      desc 'Collect open GitHub pull requests'

      option :config,
             aliases: ['-c'],
             desc: 'Configuration file path'

      option :username,
             aliases: ['-u', '--user'],
             desc: 'GitHub username'

      option :owners,
             aliases: ['-o'],
             type: :array,
             desc: 'Repository owners'

      option :token,
             desc: 'GitHub token'

      option :repositories_csv,
             desc: 'Repository cache CSV path'

      option :pull_requests_dir,
             desc: 'Directory for pull request runs'

      option :limit,
             aliases: ['-l'],
             desc: 'Maximum number of pull requests'

      option :refresh,
             aliases: ['-r'],
             type: :boolean,
             desc: 'Refresh repositories from GitHub'

      option :skip_archived,
             type: :boolean,
             desc: 'Skip archived repositories'

      option :skip_drafts,
             type: :boolean,
             desc: 'Ignore draft pull requests'

      option :exclude_repositories,
             aliases: ['--exclude-repos'],
             type: :array,
             desc: 'Repositories to exclude, in owner/name format'

      option :save_pull_requests,
             type: :boolean,
             desc: 'Save pull requests to CSV'

      option :progress,
             type: :boolean,
             desc: 'Show progress bars'

      option :log_level,
             values: Config::Builder::LOG_LEVELS.keys,
             desc: 'Log level'

      option :workers,
             aliases: ['-w'],
             desc: 'Number of repository scan workers'

      option :version,
             aliases: ['-v'],
             type: :flag,
             desc: 'Show version'

      def call(version: false, config: nil, **options)
        if version
          puts NyaPr::VERSION
          return
        end

        file_options = Config::Loader.load(config)

        app_config = Config::Builder.build(
          options,
          file_options: file_options
        )

        NyaPr.logger.level = app_config.log_level

        RunnerFactory.build(app_config).run
      end
    end
  end
end
