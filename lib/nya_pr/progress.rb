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
      @started_at = monotonic_time
      @mutex = Mutex.new

      render if enabled?
    end

    def advance(step = 1)
      return unless enabled?

      mutex.synchronize do
        @current = [@current + step, total].min
        render
      end
    end

    def finish
      return unless enabled?

      mutex.synchronize do
        render
        output.puts
        output.flush
      end
    end

    private

    attr_reader :current, :started_at, :mutex

    def enabled?
      @enabled && total.positive?
    end

    def render
      output.print(
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

      "#{minutes}m #{seconds.to_s.rjust(2, '0')}s"
    end

    def monotonic_time
      Process.clock_gettime(Process::CLOCK_MONOTONIC)
    end
  end
end
