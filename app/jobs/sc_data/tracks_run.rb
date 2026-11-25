# frozen_string_literal: true

module ScData
  # Runs a job as an import an admin can follow: its progress while it works,
  # and afterwards what it attached and what it could not take in.
  #
  # One entry that fails does not fail the run, so whatever the job logs as a
  # warning or an error is kept on the import. Without it a run that skipped
  # half its files would read as a clean one.
  module TracksRun
    # The block answers with what the run did, as the import's output.
    private def track_run(import_class, admin_user_id: nil)
      import = import_class.create!(admin_user_id:)
      import.start!

      @problems = []
      @progress = ::Imports::Progress.new(import, steps: 1)

      output = yield

      while_running(import) do
        import.update!(output: output.merge(problems: @problems), info: run_summary(output))
        import.finish!
      end
    rescue => e
      while_running(import) do
        import.info = e.message
        import.fail!
      end

      raise
    ensure
      @problems = @progress = nil
    end

    # An admin may have cleared the run meanwhile.
    private def while_running(import)
      import&.with_lock { yield if import.started? }
    end

    private def run_summary(output)
      attached = output.fetch(:attached)
      unknown = output.fetch(:unknown, [])
      removed = output.fetch(:removed, 0)

      [
        attached.any? ? "attached #{attached.values.sum(&:size)} files to #{attached.size} entries" : "no files attached",
        ("#{removed} removed" if removed.positive?),
        ("#{unknown.size} unknown" if unknown.any?),
        ("#{@problems.size} problem(s)" if @problems.any?)
      ].compact.join(", ")
    end

    private def log(level, message)
      Rails.logger.public_send(level, "[sc_data] #{self.class.name.demodulize} #{message}")

      @problems&.push(message) unless level == :info
    end
  end
end
