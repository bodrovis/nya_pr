# frozen_string_literal: true

require_relative 'lib/nya_pr'


begin
  NyaPr.run
rescue NyaPr::Error => e
  warn "nya-pr: #{e.message}"
  exit 1
rescue Interrupt
  warn "\nnya-pr: interrupted"
  exit 130
end
