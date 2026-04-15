# frozen_string_literal: true

# Shared examples for the import-wrapping job pattern.
# Tests that a job creates an import record, runs the loader, finishes the import on success,
# and marks it as failed on error.
#
# Required parameters:
#   import_class: The import model class (e.g. Imports::ModelImport)
#   loader_class: The loader class to mock (e.g. Rsi::ModelsLoader)
#   loader_method: The method called on the loader (e.g. :one or :all)
#   perform_args: Array of arguments to pass to perform (default: [])
#   loader_args: Array of expected arguments the loader receives (default: [])
#   before_perform: Optional proc to run before perform (e.g. for config stubs)
#
# Example:
#   include_examples "import_wrapping_job",
#     import_class: Imports::ModelImport,
#     loader_class: Rsi::ModelsLoader,
#     loader_method: :one,
#     perform_args: [123],
#     loader_args: [123]

RSpec.shared_examples "import_wrapping_job" do |import_class:, loader_class:, loader_method:, perform_args: [], loader_args: [], before_perform: nil|
  describe "#perform" do
    it "creates an import, runs the loader, and finishes the import" do
      loader = instance_double(loader_class)
      allow(loader_class).to receive(:new).and_return(loader)
      allow(loader).to receive(loader_method)
      instance_exec(&before_perform) if before_perform

      described_class.new.perform(*perform_args)

      import = import_class.last

      expect(import).to be_present
      expect(import.aasm_state).to eq("finished")
      if loader_args.empty?
        expect(loader).to have_received(loader_method).with(no_args)
      else
        expect(loader).to have_received(loader_method).with(*loader_args)
      end
    end

    it "marks import as failed on error" do
      loader = instance_double(loader_class)
      allow(loader_class).to receive(:new).and_return(loader)
      allow(loader).to receive(loader_method).and_raise(StandardError, "loader error")
      instance_exec(&before_perform) if before_perform

      expect { described_class.new.perform(*perform_args) }.to raise_error(StandardError, "loader error")

      import = import_class.last

      expect(import.aasm_state).to eq("failed")
      expect(import.info).to eq("loader error")
    end
  end
end
