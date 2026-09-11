# frozen_string_literal: true

module NyaPr
  class Client
    attr_reader :token, :options

    def initialize(token, **options)
      @token = token
      @options = options
    end
  end
end
