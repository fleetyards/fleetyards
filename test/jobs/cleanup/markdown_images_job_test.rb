# frozen_string_literal: true

require "test_helper"

module Cleanup
  class MarkdownImagesJobTest < ActiveJob::TestCase
    setup do
      @fleet = create(:fleet, created_by: create(:user).id)
    end

    test "#perform deletes an old image no text names" do
      image = old_image

      ::Cleanup::MarkdownImagesJob.new.perform

      refute MarkdownImage.exists?(image.id)
    end

    test "#perform keeps an image a description embeds" do
      image = old_image
      @fleet.update_columns(description: "Our banner\n\n![cover](https://api.fleetyards.test/v1/markdown-images/#{image.id}/){width=50%}")

      ::Cleanup::MarkdownImagesJob.new.perform

      assert MarkdownImage.exists?(image.id)
    end

    test "#perform keeps an image embedded in another kind of text" do
      image = old_image
      event = create(:fleet_event, fleet: @fleet)
      event.update_columns(briefing: "![map](/v1/markdown-images/#{image.id})")

      ::Cleanup::MarkdownImagesJob.new.perform

      assert MarkdownImage.exists?(image.id)
    end

    # An admin can revert a fleet's description to one of its versions, which
    # would bring the image back into the text.
    test "#perform keeps an image an earlier version of a description names" do
      image = old_image
      @fleet.update!(description: "![cover](/v1/markdown-images/#{image.id})")
      @fleet.update!(description: "No picture any more")

      ::Cleanup::MarkdownImagesJob.new.perform

      assert MarkdownImage.exists?(image.id)
    end

    test "#perform keeps an image named by an uppercase id" do
      image = old_image
      @fleet.update_columns(description: "![cover](/v1/markdown-images/#{image.id.upcase})")

      ::Cleanup::MarkdownImagesJob.new.perform

      assert MarkdownImage.exists?(image.id)
    end

    # A deleted record cannot be reverted, so its history holds nothing back.
    test "#perform deletes an image only a deleted record's history names" do
      image = old_image
      contract = create(:fleet_contract, fleet: @fleet)
      contract.update!(description: "![map](/v1/markdown-images/#{image.id})")
      contract.destroy!

      ::Cleanup::MarkdownImagesJob.new.perform

      refute MarkdownImage.exists?(image.id)
    end

    # A purged fleet can be rebuilt from its destroy snapshot, description and
    # all, so that snapshot still counts.
    test "#perform keeps an image a purged fleet's description names" do
      image = old_image
      @fleet.update!(description: "![banner](/v1/markdown-images/#{image.id})")
      @fleet.destroy!
      refute Fleet.unscoped.exists?(@fleet.id)
      assert PaperTrail::Version.exists?(item_type: "Fleet", item_id: @fleet.id, event: "destroy")

      ::Cleanup::MarkdownImagesJob.new.perform

      assert MarkdownImage.exists?(image.id)
    end

    # Only the latest snapshot can be restored, so an image only an older one
    # names is gone for good.
    test "#perform deletes an image only an earlier purge of a fleet names" do
      earlier = old_image
      latest = old_image
      purged_fleet_id = SecureRandom.uuid
      purge(purged_fleet_id, earlier, at: 2.days.ago)
      purge(purged_fleet_id, latest, at: 1.day.ago)

      ::Cleanup::MarkdownImagesJob.new.perform

      refute MarkdownImage.exists?(earlier.id)
      assert MarkdownImage.exists?(latest.id)
    end

    # Versions keep whole seconds, and which of two snapshots from the same one
    # the restorer takes is not settled, so both count.
    test "#perform keeps the images of every snapshot from a fleet's last purge" do
      first = old_image
      second = old_image
      purged_fleet_id = SecureRandom.uuid
      at = 1.day.ago.change(usec: 0)
      purge(purged_fleet_id, first, at:)
      purge(purged_fleet_id, second, at:)

      ::Cleanup::MarkdownImagesJob.new.perform

      assert MarkdownImage.exists?(first.id)
      assert MarkdownImage.exists?(second.id)
    end

    test "#perform keeps a new image its form may not have saved yet" do
      image = create(:markdown_image)

      ::Cleanup::MarkdownImagesJob.new.perform

      assert MarkdownImage.exists?(image.id)
    end

    # A destroy snapshot of a fleet that no longer exists, naming the image.
    private def purge(fleet_id, image, at:)
      PaperTrail::Version.create!(
        item_type: "Fleet", item_id: fleet_id, event: "destroy", created_at: at,
        object: {description: "![banner](/v1/markdown-images/#{image.id})"}
      )
    end

    private def old_image
      create(:markdown_image).tap do |image|
        image.update_columns(created_at: (MarkdownImage::UNREFERENCED_GRACE + 1.day).ago)
      end
    end
  end
end
