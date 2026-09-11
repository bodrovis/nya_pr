# frozen_string_literal: true

module NyaPr
  module PullRequest
    class Printer
      def print(pull_requests)
        grouped_pull_requests(pull_requests).each do |repository, repository_pull_requests|
          print_repository(repository, repository_pull_requests)
        end
      end

      private

      def grouped_pull_requests(pull_requests)
        pull_requests.group_by do |pull_request|
          pull_request['repository']
        end
      end

      def print_repository(repository, pull_requests)
        puts
        puts repository
        puts '-' * repository.length

        pull_requests.each do |pull_request|
          puts format_pull_request(pull_request)
          puts
        end
      end

      def format_pull_request(pull_request)
        draft = pull_request['draft'] ? ' [DRAFT]' : ''

        <<~OUTPUT.chomp
          ##{pull_request['number']}#{draft} #{pull_request['title']}
            Author: @#{pull_request['author']}
            #{pull_request['html_url']}
        OUTPUT
      end
    end
  end
end
