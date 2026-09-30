# frozen_string_literal: true

require "test_helper"

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

  test "is removed with its user" do
    create(:markdown_image, user: @user)

    assert_difference -> { MarkdownImage.count }, -1 do
      @user.destroy!
    end
  end

  private def upload(fixture, content_type)
    ActiveStorage::Blob.create_and_upload!(io: file_fixture(fixture).open, filename: fixture, content_type:)
  end

  private def insert_images(count, created_at:)
    MarkdownImage.insert_all(Array.new(count) { {user_id: @user.id, created_at:, updated_at: created_at} })
  end
end
