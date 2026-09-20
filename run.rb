# frozen_string_literal: true

require_relative 'lib/nya_pr'

started_at = Process.clock_gettime(Process::CLOCK_MONOTONIC)

begin
  NyaPr.run
rescue NyaPr::Error => e
  warn "nya-pr: #{e.message}"
  exit 1
rescue Interrupt
  warn "\nnya-pr: interrupted"
  exit 130
ensure
  finished_at = Process.clock_gettime(Process::CLOCK_MONOTONIC)
  elapsed = finished_at - started_at

  warn format('Elapsed: %.3f seconds', elapsed)
end
