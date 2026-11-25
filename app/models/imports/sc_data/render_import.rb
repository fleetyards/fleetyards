# frozen_string_literal: true

module Imports
  module ScData
    # A run over the published renders. These run every night and
    # mostly find nothing new.
    class RenderImport < ::Import
      def jbuilder_template_path
        "api/v1/imports/import"
      end

      def jbuilder_template_instance_name
        :import
      end

      private def report_run
        return if finished? && !changed_anything? && !new_problems?

        super
      end

      private def report_severity
        (finished? && problems.any?) ? :warning : super
      end

      private def changed_anything?
        output.to_h["attached"].present? || output.to_h["removed"].to_i.positive?
      end

      # A problem nobody has fixed since the last run was reported by that one.
      private def new_problems?
        (kinds(problems) - kinds(previous_problems)).any?
      end

      # Which entry, and what went wrong with it: an error's own message can
      # carry a request id or a path that is another one every run.
      private def kinds(problems)
        problems.map { |problem| problem.split(": ").first(2) }.uniq
      end

      private def problems = Array(output.to_h["problems"])

      private def previous_problems
        previous = self.class.finished.where.not(id:).order(finished_at: :desc).first

        Array(previous&.output.to_h["problems"])
      end
    end
  end
end
