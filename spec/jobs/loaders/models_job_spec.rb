# frozen_string_literal: true

require "rails_helper"

RSpec.describe Loaders::ModelsJob do
  include_examples "import_wrapping_job",
    import_class: Imports::ModelsImport,
    loader_class: Rsi::ModelsLoader,
    loader_method: :all
end
