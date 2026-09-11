# frozen_string_literal: true

require "open3"

module CliHelpers
  SPINNER = %w[⠋ ⠙ ⠹ ⠸ ⠼ ⠴ ⠦ ⠧ ⠇ ⠏].freeze
  STATUS_LABELS = {ok: "OK", failed: "FAILED", skipped: "skipped"}.freeze

  $stdout.sync = true

  def self.format_duration(seconds)
    seconds = seconds.round(0)
    if seconds < 60
      "#{seconds}s"
    else
      "#{seconds / 60}m#{seconds % 60}s"
    end
  end

  def self.monotonic_now
    Process.clock_gettime(Process::CLOCK_MONOTONIC)
  end

  def self.result_line(status, elapsed)
    "#{STATUS_LABELS.fetch(status)} (#{elapsed ? format_duration(elapsed) : "-"})"
  end

  # Runs a step's block or shell command; returns [status, output].
  def self.execute_step(cmd, block)
    if block
      block.call
      [:ok, ""]
    else
      output, status = Open3.capture2e(cmd)
      [status.success? ? :ok : :failed, output]
    end
  end

  def self.with_spinner(label)
    start_time = monotonic_now

    spinning = true
    spin_thread = nil
    if $stdout.tty?
      frame = 0
      spin_thread = Thread.new do
        while spinning
          print "\r  #{label}...#{SPINNER[frame % SPINNER.size]} "
          frame += 1
          sleep 0.08
        end
      end
    else
      print "  #{label}..."
    end

    begin
      status, output = yield
    rescue Interrupt
      spinning = false
      spin_thread&.join
      print "\r  #{label}...interrupted#{" " * 20}\n"
      abort
    end

    spinning = false
    spin_thread&.join

    line = result_line(status, monotonic_now - start_time)
    print $stdout.tty? ? "\r  #{label}...#{line}#{" " * 20}\n" : "#{line}\n"
    return if status == :ok

    print "\n"
    warn output
    abort
  end

  # `async: true` returns a step handle whose thread runs once every step in
  # `after:` finished :ok; otherwise the step is :skipped, so one failure
  # surfaces once instead of cascading. The thread returns
  # [status, output, elapsed]; collect the handles with run_step_wait.
  def self.run_step(label, cmd = nil, verbose: false, async: false, after: [], &block)
    if async
      step = {label: label}
      step[:thread] = Thread.new do
        next [:skipped, "", nil] unless after.all? { |dep| dep[:thread].value.first == :ok }

        step[:start_time] = monotonic_now
        status, output = execute_step(cmd, block)
        [status, output, monotonic_now - step[:start_time]]
      end
      return step
    end

    if verbose
      puts "\n== #{label} =="
      if block
        block.call
        return
      end
      return if system(cmd)
      abort "\n  #{label} failed!"
    end

    with_spinner(label) { execute_step(cmd, block) }
  end

  def self.run_step_wait(*steps, verbose: false)
    results = Array.new(steps.size)

    if $stdout.tty? && !verbose
      # Reserve one line per step
      steps.each { print "\n" }
      frame = 0

      loop do
        print "\033[#{steps.size}A"

        steps.each_with_index do |step, i|
          results[i] ||= step[:thread].value unless step[:thread].alive?
          indicator =
            if results[i]
              result_line(results[i][0], results[i][2])
            elsif step[:start_time]
              SPINNER[frame % SPINNER.size]
            else
              "waiting"
            end
          print "\r  #{step[:label]}...#{indicator}#{" " * 20}\n"
        end

        break if results.all?
        frame += 1
        sleep 0.08
      end
    else
      # No spinner: report each step as it finishes, in list order
      steps.each_with_index do |step, i|
        puts "\n== #{step[:label]} ==" if verbose
        results[i] = step[:thread].value
        line = result_line(results[i][0], results[i][2])
        puts verbose ? "  #{line}" : "  #{step[:label]}...#{line}"
      end
    end

    failed = steps.zip(results).select { |_, (status, _, _)| status == :failed }
    return if failed.empty?

    print "\n"
    warn failed.map { |step, (_, output, _)| "== #{step[:label]} ==\n#{output}" }.join("\n")
    abort
  end
end
