# frozen_string_literal: true

module Loaders
  class ModulesImportJob < ::Loaders::BaseJob
    def perform
      results = ::ModulesImporter.new.run

      body = modules_import_body(results)

      GithubIssueCreator.new(
        task_type: "modules_import",
        title: "Modules Import Results",
        body:
      ).run
    end

    private def modules_import_body(results)
      lines = []

      lines << "## New Modules (#{results[:new][:count] || 0})"
      lines << ""
      if results[:new][:items].present?
        results[:new][:items].each do |mod|
          lines << "- **#{mod[:model_name]} #{mod[:name]}**"
        end
      else
        lines << "No new Modules found"
      end

      if results[:new_with_error][:items].present?
        lines << ""
        lines << "## New Modules with Errors (#{results[:new_with_error][:count]})"
        lines << ""
        results[:new_with_error][:items].each do |mod|
          lines << "- **#{mod[:model_name]} #{mod[:name]}**"
        end
      end

      if results[:model_not_found][:items].present?
        lines << ""
        lines << "## Missing Models (#{results[:model_not_found][:count]})"
        lines << ""
        results[:model_not_found][:items].each do |mod|
          lines << "- **#{mod[:model_name]} #{mod[:name]}**"
        end
      end

      lines.join("\n")
    end
  end
end
