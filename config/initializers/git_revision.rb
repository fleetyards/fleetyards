# frozen_string_literal: true

module Git
  module_function def revision
    @revision ||= begin
      File.read(Rails.root.join('REVISION')).chomp if File.exist?(Rails.root.join('REVISION'))
    end
  end

  module_function def revision_short
    @revision_short ||= (revision || '').slice(0, 7)
  end
end

Git.revision_short
