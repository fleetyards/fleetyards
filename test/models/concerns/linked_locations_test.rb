# frozen_string_literal: true

require "test_helper"

class LinkedLocationsTest < ActiveSupport::TestCase
  setup do
    @lorville = create(:location, name: "Lorville", kind: "city")
    @inventory = create(:inventory, location: nil)
  end

  test "linking a place with no text of its own fills the text with its name" do
    @inventory.update!(location_id: @lorville.id)

    assert_equal "Lorville", @inventory.location
  end

  test "linking a place keeps the text that came with it" do
    @inventory.update!(location_id: @lorville.id, location: "Lorville, Teasa Spaceport")

    assert_equal ["Lorville, Teasa Spaceport", @lorville.id], [@inventory.location, @inventory.location_id]
  end

  test "retyping the text away from the linked name drops the link" do
    @inventory.update!(location_id: @lorville.id)
    @inventory.update!(location: "Somewhere on Hurston")

    assert_nil @inventory.location_id
  end

  test "a free-text place stays unlinked" do
    @inventory.update!(location: "My secret base")

    assert_nil @inventory.location_id
  end
end
