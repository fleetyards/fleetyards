module Imports
  class ModelsImport < ::Import
    belongs_to :admin_user, optional: true
  end
end
