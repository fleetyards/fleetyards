# frozen_string_literal: true

module Git
  module_function def revision
    @revision ||= Rails.root.join("REVISION").read.chomp if Rails.root.join("REVISION").exist?
  end

  module_function def revision_short
    @revision_short ||= (revision || "").slice(0, 7)
  end
end

Git.revision_short
