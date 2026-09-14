# frozen_string_literal: true

module NyaPr
  class Progress
    DEFAULT_WIDTH = 30

    attr_reader :title, :total, :width, :output

    def initialize(
      title,
      total:,
      enabled: true,
      width: DEFAULT_WIDTH,
      output: $stderr
    )
      @title = title
      @total = total
      @width = width
      @output = output
      @enabled = enabled
      @current = 0

      # Use a monotonic clock so elapsed time is not affected by system
      # clock changes while the progress bar is running.
      @started_at = monotonic_time

      # Progress may be updated by multiple worker threads. The mutex keeps
      # the counter update and terminal rendering atomic relative to each
      # other, preventing lost increments and interleaved output.
      @mutex = Mutex.new

      render if enabled?
    end

    def advance(step = 1)
      return unless enabled?

      mutex.synchronize do
        # Never allow the displayed counter to exceed the expected total.
        @current = [@current + step, total].min
        render
      end
    end

    def finish
      return unless enabled?

      mutex.synchronize do
        # Render the final known state, then move subsequent output
        # to a new terminal line.
        render
        output.puts
        output.flush
      end
    end

    private

    attr_reader :current, :started_at, :mutex

    def enabled?
      # A zero-sized task does not need a progress bar.
      @enabled && total.positive?
    end

    def render
      output.print(
        # Return to the beginning of the line and clear the previous render.
        "\r\e[2K",
        title,
        ' [',
        progress_bar,
        '] ',
        "#{current}/#{total} ",
        "#{percentage}% ",
        "ETA #{eta}"
      )
      output.flush
    end

    def progress_bar
      completed = (width * progress).round
      remaining = width - completed

      ('█' * completed) + ('░' * remaining)
    end

    def progress
      current.to_f / total
    end

    def percentage
      (progress * 100).round
    end

    def eta
      return '--' if current.zero?

      elapsed = monotonic_time - started_at
      rate = current / elapsed

      return '--' unless rate.positive?

      seconds = ((total - current) / rate).round

      format_duration(seconds)
    end

    def format_duration(seconds)
      return "#{seconds}s" if seconds < 60

      minutes, seconds = seconds.divmod(60)
      return "#{minutes}m #{seconds.to_s.rjust(2, '0')}s" if minutes < 60

      hours, minutes = minutes.divmod(60)

      "#{hours}h #{minutes.to_s.rjust(2, '0')}m"
    end

    def monotonic_time
      Process.clock_gettime(Process::CLOCK_MONOTONIC)
    end
  end
end
