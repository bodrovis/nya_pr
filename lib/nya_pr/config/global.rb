# frozen_string_literal: true

module NyaPr
  module Config
    Global = Data.define(
      *Schema.key_map.dump
    )
  end
end
