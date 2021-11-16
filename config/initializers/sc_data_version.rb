# frozen_string_literal: true

module ScData
  module_function def current_version
    @current_version ||= begin
      version_file = Rails.root.join('public/sc_data/.version')

      File.read(version_file).strip if File.exist?(version_file)
    end
  end
end

ScData.current_version
