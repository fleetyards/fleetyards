# frozen_string_literal: true

module CliHelpers
  SPINNER = %w[⠋ ⠙ ⠹ ⠸ ⠼ ⠴ ⠦ ⠧ ⠇ ⠏].freeze

  $stdout.sync = true

  def self.format_duration(seconds)
    seconds = seconds.round(0)
    if seconds < 60
      "#{seconds}s"
    else
      "#{seconds / 60}m#{seconds % 60}s"
    end
  end

  def self.with_spinner(label)
    start_time = Process.clock_gettime(Process::CLOCK_MONOTONIC)

    spinning = true
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
      success, output = yield
    rescue Interrupt
      spinning = false
      spin_thread&.join
      print "\r  #{label}...interrupted#{" " * 20}\n"
      abort
    end

    spinning = false
    spin_thread&.join

    elapsed = Process.clock_gettime(Process::CLOCK_MONOTONIC) - start_time
    time_str = format_duration(elapsed)

    if success
      if $stdout.tty?
        print "\r  #{label}...OK (#{time_str})#{" " * 20}\n"
      else
        puts "OK (#{time_str})"
      end
    else
      if $stdout.tty?
        print "\r  #{label}...FAILED (#{time_str})#{" " * 20}\n\n"
      else
        puts "FAILED (#{time_str})\n"
      end
      warn output
      abort
    end
  end

  def self.run_step(label, cmd = nil, verbose: false, async: false, &block)
    if async
      thread = Thread.new do
        if block
          block.call
          [true, ""]
        else
          output, status = Open3.capture2e(cmd)
          [status.success?, output]
        end
      end
      return {label: label, thread: thread, start_time: Process.clock_gettime(Process::CLOCK_MONOTONIC)}
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

    with_spinner(label) do
      if block
        block.call
        [true, ""]
      else
        output, status = Open3.capture2e(cmd)
        [status.success?, output]
      end
    end
  end

  def self.run_step_wait(*steps, verbose: false)
    if verbose
      steps.each do |step|
        puts "\n== #{step[:label]} =="
        success, output = step[:thread].value
        elapsed = Process.clock_gettime(Process::CLOCK_MONOTONIC) - step[:start_time]
        puts "  (#{format_duration(elapsed)})"
        next if success
        warn output
        abort "\n  #{step[:label]} failed!"
      end
      return
    end

    if $stdout.tty?
      steps.each { |_| print "\n" }

      finished = Array.new(steps.size)
      frame = 0

      loop do
        print "\033[#{steps.size}A"

        steps.each_with_index do |step, i|
          if finished[i]
            f = finished[i]
            status = f[:success] ? "OK" : "FAILED"
            print "\r  #{step[:label]}...#{status} (#{f[:time_str]})#{" " * 20}\n"
          elsif step[:thread].alive?
            print "\r  #{step[:label]}...#{SPINNER[frame % SPINNER.size]} #{" " * 20}\n"
          else
            success, output = step[:thread].value
            elapsed = Process.clock_gettime(Process::CLOCK_MONOTONIC) - step[:start_time]
            time_str = format_duration(elapsed)
            finished[i] = {success: success, output: output, time_str: time_str}
            status = success ? "OK" : "FAILED"
            print "\r  #{step[:label]}...#{status} (#{time_str})#{" " * 20}\n"
          end
        end

        break if finished.all?
        frame += 1
        sleep 0.08
      end

      failed = steps.each_with_index.filter_map { |step, i| [step, finished[i]] unless finished[i][:success] }
      unless failed.empty?
        print "\n"
        warn failed.map { |step, f| "== #{step[:label]} ==\n#{f[:output]}" }.join("\n")
        abort
      end
    else
      results = steps.map { |s| [s, s[:thread].value] }
      results.each do |step, (success, output)|
        elapsed = Process.clock_gettime(Process::CLOCK_MONOTONIC) - step[:start_time]
        time_str = format_duration(elapsed)
        if success
          puts "  #{step[:label]}...OK (#{time_str})"
        else
          puts "  #{step[:label]}...FAILED (#{time_str})\n"
          warn output
          abort
        end
      end
    end
  end
end
