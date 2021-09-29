# frozen_string_literal: true

class ApiLoader
  attr_accessor :identifier

  def initialize(identifier)
    self.identifier = identifier
  end

  def schemas
    @schemas ||= load_files("schemas")
  end

  def parameters
    @parameters ||= load_files("parameters")
  end

  private def load_files(type)
    Dir.glob(Rails.root.join("api/#{type}/#{identifier}/**/*")).filter_map do |file|
      next if File.directory?(file)

      {File.basename(file, File.extname(file)).camelize => instance_eval(File.read(file))}
    end.reduce(:merge)
  end
end
