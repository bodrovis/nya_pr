# frozen_string_literal: true

require 'dry/schema'

module NyaPr
  module Config
    STRICT_BOOL = Dry::Types['strict.bool']

    private_constant :STRICT_BOOL

    Schema = Dry::Schema.Params do
      config.validate_keys = true

      required(:username).filled(:string)

      required(:owners).array(:string)

      required(:token).maybe(:string)
      required(:repositories_csv).maybe(:string)
      required(:pull_requests_dir).maybe(:string)

      required(:limit).filled(
        :integer,
        gt?: 0
      )

      required(:workers).filled(
        :integer,
        gt?: 0
      )

      required(:refresh).value(STRICT_BOOL)
      required(:skip_archived).value(STRICT_BOOL)
      required(:skip_drafts).value(STRICT_BOOL)
      required(:save_pull_requests).value(STRICT_BOOL)
      required(:progress).value(STRICT_BOOL)

      required(:exclude_repositories).array(:string)

      required(:log_level).filled(
        :string,
        included_in?: %w[
          debug
          info
          warn
          error
          fatal
        ]
      )
    end
  end
end
