# frozen_string_literal: true

require "rails_helper"

RSpec.describe Loaders::ModelJob do
  include_examples "import_wrapping_job",
    import_class: Imports::ModelImport,
    loader_class: Rsi::ModelsLoader,
    loader_method: :one,
    perform_args: [123],
    loader_args: [123]
end
