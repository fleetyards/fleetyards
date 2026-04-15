# frozen_string_literal: true

require "rails_helper"

RSpec.describe Loaders::ScData::ModelsJob do
  include_examples "import_wrapping_job",
    import_class: Imports::ScData::ModelsImport,
    loader_class: ScData::Loader::ModelsLoader,
    loader_method: :all,
    before_perform: -> { allow(Rails.configuration).to receive(:sc_data).and_return({version: "3.24.0", environment: "live"}) }
end
