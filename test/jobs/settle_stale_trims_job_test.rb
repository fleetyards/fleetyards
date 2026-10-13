# frozen_string_literal: true

require "test_helper"

class SettleStaleTrimsJobTest < ActiveSupport::TestCase
  include ActionCable::TestHelper

  test "#perform takes lost crops off and tells admins" do
    admin_user = create(:admin_user, resource_access: [:models])
    model = create(:model)
    model.update_columns(pending_trims: {"top_view" => 16.minutes.ago.iso8601(6)})

    assert_broadcasts(AdminModelMediaChannel.broadcasting_for(admin_user), 1) do
      SettleStaleTrimsJob.new.perform
    end

    assert_empty model.reload.pending_trims
  end

  test "#perform leaves crops still on their way" do
    model = create(:model)
    model.update_columns(pending_trims: {"top_view" => 1.minute.ago.iso8601(6)})

    SettleStaleTrimsJob.new.perform

    assert_equal %w[top_view], model.reload.pending_trims.keys
  end

  test "is scheduled" do
    schedule = YAML.safe_load(ERB.new(Rails.root.join("config/sidekiq_schedule.yml").read).result)

    assert_equal "SettleStaleTrimsJob", schedule.dig("settle_stale_trims_job", "class")
  end
end
