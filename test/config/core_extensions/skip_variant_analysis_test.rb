# frozen_string_literal: true

require "test_helper"

class SkipVariantAnalysisTest < ActiveSupport::TestCase
  setup do
    @blob = ActiveStorage::Blob.create_and_upload!(
      io: Rails.root.join("test/fixtures/files/test.png").open,
      filename: "test.png",
      content_type: "image/png"
    )
  end

  test "an upload is still analysed" do
    @blob.expects(:analyze_later).once

    create(:user).avatar.attach(@blob)
  end

  test "a processed variant is not" do
    ActiveStorage::Blob.any_instance.expects(:analyze_later).never

    @blob.variant(resize_to_limit: [10, 10]).processed

    assert_predicate ActiveStorage::VariantRecord.where(blob: @blob), :exists?
  end
end
