# frozen_string_literal: true

require "test_helper"

class NoVectorImageValidatorTest < ActiveSupport::TestCase
  VECTOR = "vector.svg"
  RASTER = "test.png"

  # Every attachment an account holder can write to. Listed in one place so an
  # attachment added to a user-facing model without the validation shows up as
  # a failing test rather than as a quiet way back in.
  def user_facing_attachments
    user = create(:user)

    {
      "User#avatar" => [user, :avatar],
      # Reloaded: a freshly built fleet still holds the empty membership its
      # own callback put there, which fails validation for reasons of its own.
      "Fleet#logo" => [create(:fleet).reload, :logo],
      "Fleet#background_image" => [create(:fleet).reload, :background_image],
      "Inventory#image" => [create(:inventory, holder: user), :image],
      "FleetInventory#image" => [create(:fleet_inventory), :image],
      "InventoryItem#image" => [create(:inventory_item), :image],
      "FleetInventoryItem#image" => [create(:fleet_inventory_item), :image],
      "Imports::HangarImport#import" => [Imports::HangarImport.new(user:), :import]
    }
  end

  test "every attachment a user can write refuses a vector" do
    user_facing_attachments.each do |label, (record, attribute)|
      record.public_send(attribute).attach(attachable(VECTOR))

      assert_not record.valid?, "#{label} accepted an SVG"
      assert_includes record.errors[attribute], "must not be an SVG image"
    end
  end

  test "every attachment a user can write takes a raster image" do
    user_facing_attachments.each do |label, (record, attribute)|
      record.public_send(attribute).attach(attachable(RASTER))

      assert record.valid?, "#{label} rejected a PNG: #{record.errors.full_messages.to_sentence}"
    end
  end

  # The catalogue artwork is the reason SVG is served inline at all, and it is
  # attached by the sc_data loaders, which no request reaches.
  test "the images the sc_data loaders write may still be vectors" do
    commodity = create(:commodity)

    commodity.store_image.attach(attachable(VECTOR))

    assert_predicate commodity.reload.store_image, :attached?
  end

  # Rows written before this validation existed keep whatever they carry, so
  # the check looks only at what a save is attaching. Re-checking an untouched
  # attachment would leave the record uneditable for good.
  test "an SVG already attached does not fail later saves" do
    user = create(:user)
    ActiveStorage::Attachment.create!(record: user, name: "avatar", blob: blob(VECTOR))

    user.reload

    assert_predicate user, :valid?
    assert user.update(username: "renamed")
  end

  test "clearing an attachment is not an attach" do
    user = create(:user)
    ActiveStorage::Attachment.create!(record: user, name: "avatar", blob: blob(VECTOR))

    user.reload.avatar = nil

    assert_predicate user, :valid?
  end

  private def attachable(fixture)
    {io: file_fixture(fixture).open, filename: fixture}
  end

  private def blob(fixture)
    ActiveStorage::Blob.create_and_upload!(**attachable(fixture))
  end
end
