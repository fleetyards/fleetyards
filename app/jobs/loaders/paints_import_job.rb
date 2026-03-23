# frozen_string_literal: true

module Loaders
  class PaintsImportJob < ::Loaders::BaseJob
    def perform
      results = ::PaintsImporter.new.run

      body = paints_import_body(results)

      GithubIssueCreator.new(
        task_type: "paints_import",
        title: "Paints Import Results",
        body:
      ).run
    end

    private def paints_import_body(results)
      lines = []

      lines << "## New Paints (#{results[:new][:count] || 0})"
      lines << ""
      if results[:new][:items].present?
        results[:new][:items].each do |paint|
          lines << "- **#{paint[:model_name]} #{paint[:name]}**"
        end
      else
        lines << "No new Paints found"
      end

      if results[:new_with_error][:items].present?
        lines << ""
        lines << "## New Paints with Errors (#{results[:new_with_error][:count]})"
        lines << ""
        results[:new_with_error][:items].each do |paint|
          lines << "- **#{paint[:model_name]} #{paint[:name]}**"
        end
      end

      if results[:model_not_found][:items].present?
        lines << ""
        lines << "## Missing Models (#{results[:model_not_found][:count]})"
        lines << ""
        results[:model_not_found][:items].each do |paint|
          lines << "- **#{paint[:model_name]} #{paint[:name]}**"
        end
      end

      lines.join("\n")
    end
  end
end
