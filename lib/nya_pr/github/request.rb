# frozen_string_literal: true

require 'oj'

module NyaPr
  module Github
    module Request
      include Connection

      MAX_PAGES = 1_000
      PER_PAGE = 100

      def get(path, params = {})
        _response, body = do_get(path, params)

        body
      end

      def paginate(path, params = {})
        params = params.merge(per_page: params.fetch(:per_page, PER_PAGE))

        page = 1
        result = []

        loop do
          raise NyaPr::Error, 'Pagination limit exceeded' if page > MAX_PAGES

          NyaPr.logger.debug("Fetching page #{page} for #{path}")
          response, body = do_get(path, params.merge(page: page))

          raise NyaPr::Error, 'Expected paginated response to be an array' unless body.is_a?(Array)

          result.concat(body)

          break if body.empty?
          break unless next_page?(response)

          page += 1
        end

        result
      end

      private

      def do_get(path, params = {})
        prepared_path = prepare(path)

        NyaPr.logger.debug("GET #{prepared_path} #{params.inspect}")

        response = connection(client).get(prepared_path, params)
        body = parse_body(response)

        NyaPr.logger.debug(
          "GET #{prepared_path} -> HTTP #{response.status}"
        )

        raise_on_error!(response, body, prepared_path)

        [response, body]
      end

      def parse_body(response)
        return nil if response.body.nil? || response.body.empty?

        Oj.load(response.body)
      rescue Oj::ParseError
        raise NyaPr::Error, "Failed to parse response: #{response.body}"
      end

      def raise_on_error!(response, body, path)
        return if response.success?

        message =
          if body.is_a?(Hash)
            body['message'] || body
          else
            body
          end

        raise NyaPr::Error.new(
          "GET #{path}: GitHub API error #{response.status}: #{message}",
          status: response.status
        )
      end

      def next_page?(response)
        response.headers['link']&.include?('rel="next"')
      end

      def prepare(path)
        path.
          delete_prefix('/').
          gsub(%r{//}, '/').
          gsub(%r{/+\z}, '')
      end
    end
  end
end
