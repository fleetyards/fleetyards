# frozen_string_literal: true

require "test_helper"

module ScData
  class ShipViewFieldsTest < ActiveSupport::TestCase
    # Shared with the folder upload's mapping.spec.ts.
    CASES = JSON.parse(Rails.root.join("test/fixtures/files/ship_view_filenames.json").read)

    CASES.each do |group|
      group["cases"].each do |filename, field|
        test "#{group["name"]}: #{filename}" do
          if field
            assert_equal field.underscore, ShipViewFields.field_for(filename)
          else
            assert_nil ShipViewFields.field_for(filename)
          end
        end
      end
    end

    test "every field it maps to is an attachment on Model" do
      fields = CASES.flat_map { |group| group["cases"].values }.compact.map(&:underscore).uniq
      attachments = Model.reflect_on_all_attachments.map { |attachment| attachment.name.to_s }

      assert_empty fields - attachments
    end
  end
end
