# frozen_string_literal: true

require "test_helper"

module Maintenance
  class PreprocessRepresentationsTaskTest < ActiveSupport::TestCase
    test "#collection leaves out what already has representations, and the representations themselves" do
      blob = upload("test.png")
      blob.variant(resize_to_limit: [10, 10]).processed
      variant_blob = ActiveStorage::VariantRecord.find_by!(blob:).image.blob
      bare = upload("image.jpg", content_type: "image/jpeg")

      collection = PreprocessRepresentationsTask.new.collection

      assert_includes collection, bare
      assert_not_includes collection, blob
      assert_not_includes collection, variant_blob
    end

    private def upload(name, content_type: "image/png")
      ActiveStorage::Blob.create_and_upload!(io: Rails.root.join("test/fixtures/files", name).open, filename: name, content_type:)
    end
  end
end
