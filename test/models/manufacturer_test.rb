# frozen_string_literal: true

require "test_helper"

# == Schema Information
#
# Table name: manufacturers
#
#  id              :uuid             not null, primary key
#  code            :string
#  code_mapping    :string
#  description     :text
#  icon_overridden :boolean          default(FALSE), not null
#  icon_path       :string
#  known_for       :string(255)
#  logo_overridden :boolean          default(FALSE), not null
#  long_name       :string
#  name            :string(255)
#  sc_ref          :string
#  slug            :string(255)
#  created_at      :datetime
#  updated_at      :datetime
#  rsi_id          :integer
#
# Indexes
#
#  index_manufacturers_on_slug  (slug) UNIQUE
#
class ManufacturerTest < ActiveSupport::TestCase
  # The slug is what the public API and the filters identify a manufacturer by,
  # so two rows answering to one made those lookups pick arbitrarily. The export
  # produced seventeen such pairs before the index existed.
  test "the database refuses a second manufacturer with the same slug" do
    create(:manufacturer, name: "Basilisk")

    duplicate = Manufacturer.new(name: "Basilisk")

    assert_raises(ActiveRecord::RecordNotUnique) { duplicate.save!(validate: false) }
  end

  # Names that differ only in case or punctuation slug identically, which is how
  # eleven of the pairs got in -- the index has to catch those too, not just
  # exact repeats.
  test "the database refuses a name that only differs by case" do
    create(:manufacturer, name: "Gyson Inc.")

    assert_raises(ActiveRecord::RecordNotUnique) do
      Manufacturer.new(name: "GYSON INC.").save!(validate: false)
    end
  end

  test "the database refuses a name that only differs by trailing space" do
    create(:manufacturer, name: "Basilisk")

    assert_raises(ActiveRecord::RecordNotUnique) do
      Manufacturer.new(name: "Basilisk ").save!(validate: false)
    end
  end

  test "manufacturers with distinct names are unaffected" do
    create(:manufacturer, name: "Aegis Dynamics")

    assert_difference -> { Manufacturer.count } do
      create(:manufacturer, name: "maxOx")
    end
  end

  # A unique index still allows any number of NULLs, and nothing requires a
  # manufacturer to carry a slug.
  test "more than one manufacturer may have no slug at all" do
    2.times do |index|
      manufacturer = Manufacturer.new(name: "Nameless #{index}")
      manufacturer.save!(validate: false)
      manufacturer.update_columns(slug: nil)
    end

    assert_equal 2, Manufacturer.where(slug: nil).count
  end

  # Filter lists take the export's art, which covers far more manufacturers than
  # the curated logos and so reads as one set. The logo is the ship detail
  # page's picture, not this one's.
  test "#to_filter prefers the export's icon over the curated logo" do
    manufacturer = create(:manufacturer, :with_logo, :with_icon)

    assert_equal blob_url(manufacturer.icon), manufacturer.to_filter.icon
  end

  # `to_filter` reads the `logo` attachment too, so a local variable named for
  # either one silently resolves to nil instead -- and the manufacturers with
  # only one of the two raise rather than falling back.
  test "#to_filter falls back to the curated logo when the game names no art" do
    manufacturer = create(:manufacturer, :with_logo)

    assert_not_predicate manufacturer.icon, :attached?
    assert_equal blob_url(manufacturer.logo), manufacturer.to_filter.icon
  end

  test "#to_filter leaves the icon empty when the manufacturer has no picture" do
    assert_nil create(:manufacturer).to_filter.icon
  end

  private def blob_url(attachment)
    Rails.application.routes.url_helpers.rails_blob_url(attachment)
  end
end
