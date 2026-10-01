# frozen_string_literal: true

require "test_helper"

# == Schema Information
#
# Table name: markdown_images
#
#  id         :uuid             not null, primary key
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  user_id    :uuid
#
# Indexes
#
#  index_markdown_images_on_user_id_and_created_at  (user_id,created_at)
#
# Foreign Keys
#
#  fk_rails_...  (user_id => users.id) ON DELETE => nullify
#
class MarkdownImageTest < ActiveSupport::TestCase
  setup do
    @user = create(:user)
  end

  test "takes a raster image uploaded directly" do
    image = MarkdownImage.new(user: @user, file: upload("test.png", "image/png").signed_id)

    assert image.save, image.errors.full_messages.to_sentence
    assert_equal 2826, image.file.metadata[:width]
    assert_equal [2000, 1405], image.display_dimensions
  end

  test "refuses an SVG" do
    image = MarkdownImage.new(user: @user, file: upload("vector.svg", "image/svg+xml").signed_id)

    assert_not image.valid?
    assert_includes image.errors.details[:file], {error: :svg_not_supported}
  end

  test "refuses a content type that is not a supported raster image" do
    blob = ActiveStorage::Blob.create_and_upload!(io: StringIO.new("%PDF-1.4\n%%EOF\n"), filename: "doc.pdf", content_type: "application/pdf")
    image = MarkdownImage.new(user: @user, file: blob.signed_id)

    assert_not image.valid?
    assert_includes image.errors.details[:file], {error: :image_type_not_supported}
  end

  test "refuses a file that only claims to be an image" do
    blob = ActiveStorage::Blob.create_and_upload!(io: StringIO.new("not a picture"), filename: "fake.png", content_type: "image/png", identify: false)
    image = MarkdownImage.new(user: @user, file: blob.signed_id)

    assert_not image.valid?
    assert_includes image.errors.details[:file], {error: :image_type_not_supported}
  end

  test "requires a file" do
    image = MarkdownImage.new(user: @user)

    assert_not image.valid?
    assert_includes image.errors.details[:file], {error: :blank}
  end

  test "refuses a file above the size limit" do
    blob = upload("test.png", "image/png")
    blob.update_column(:byte_size, MarkdownImage::MAX_BYTE_SIZE + 1)
    image = MarkdownImage.new(user: @user, file: blob.signed_id)

    assert_not image.valid?
    assert_includes image.errors.details[:file], {error: :file_too_large, count: 10}
    assert_not blob.reload.analyzed?, "an oversized upload is refused without being downloaded"
  end

  test "refuses more uploads once the daily limit is reached" do
    insert_images(MarkdownImage::DAILY_LIMIT, created_at: 1.hour.ago)
    image = MarkdownImage.new(user: @user, file: upload("test.png", "image/png").signed_id)

    assert_not image.valid?
    assert_includes image.errors.details[:base], {error: :markdown_image_limit_reached, count: MarkdownImage::DAILY_LIMIT}
  end

  test "uploads older than a day do not count toward the limit" do
    insert_images(MarkdownImage::DAILY_LIMIT, created_at: 25.hours.ago)
    image = MarkdownImage.new(user: @user, file: upload("test.png", "image/png").signed_id)

    assert_predicate image, :valid?
  end

  private def upload(fixture, content_type)
    ActiveStorage::Blob.create_and_upload!(io: file_fixture(fixture).open, filename: fixture, content_type:)
  end

  private def insert_images(count, created_at:)
    MarkdownImage.insert_all(Array.new(count) { {user_id: @user.id, created_at:, updated_at: created_at} })
  end

  test "refuses a blob another record already uses" do
    fleet = create(:fleet, created_by: @user.id)
    fleet.logo.attach(upload("test.png", "image/png"))
    image = MarkdownImage.new(user: @user, file: fleet.logo.blob.signed_id)

    assert_not image.valid?
    assert_includes image.errors.details[:file], {error: :file_in_use}
  end

  test "outlives the account that uploaded it" do
    image = create(:markdown_image, user: @user)

    @user.destroy!

    assert_nil image.reload.user_id
    assert image.file.attached?
  end

  # A text column on a fleet-owned table is written through the markdown editor
  # unless it is listed here. A new one has to be registered, or the cleanup job
  # would delete the images embedded in it.
  NOT_MARKDOWN = {
    "FleetInventory" => %w[description],
    "FleetEventSlot" => %w[description],
    "MissionSlot" => %w[description]
  }.freeze

  test "every fleet description column is known to the image cleanup" do
    Rails.application.eager_load!

    ApplicationRecord.descendants.each do |model|
      next if model.abstract_class? || !model.name.start_with?("Fleet", "Mission")
      next unless model.table_exists?

      columns = model.columns.select { |column| column.type == :text && column.name.in?(%w[description briefing]) }.map(&:name)
      registered = MarkdownImage::REFERENCING_COLUMNS.fetch(model.name, []).map(&:to_s)
      unaccounted = columns - registered - NOT_MARKDOWN.fetch(model.name, [])

      assert_empty unaccounted, "#{model.name} has #{unaccounted.join(", ")}: add it to MarkdownImage::REFERENCING_COLUMNS, or to NOT_MARKDOWN here if it is plain text"
    end
  end

  test "every registered column exists" do
    MarkdownImage::REFERENCING_COLUMNS.each do |class_name, columns|
      model = class_name.constantize

      columns.each { |column| assert model.column_names.include?(column.to_s), "#{class_name} has no #{column}" }
    end
  end
end
