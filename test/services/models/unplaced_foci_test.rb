# frozen_string_literal: true

require "test_helper"

module Models
  class UnplacedFociTest < ActiveSupport::TestCase
    setup do
      AdminNotificationsChannel.stubs(:broadcast_to)
    end

    test "lists each part no key fits, with the ships and the source that word it" do
      create(:model, name: "Vulture", rsi_focus: "Light Salvage / Escort")
      create(:model, name: "Arrow", sc_role: "Escort")
      create(:model, name: "Mole", rsi_focus: "Mining", sc_role: "Mining / Survey")

      entries = UnplacedFoci.call

      assert_equal %w[escort survey], entries.map(&:part)
      assert_equal [["Arrow", "game files", "Escort"], ["Vulture", "ship matrix", "Light Salvage / Escort"]],
        entries.first.ships.map { |ship| [ship.name, ship.source, ship.wording] }
      assert_equal ["Mole"], entries.last.ships.map(&:name)
    end

    test "lists nothing where every part has a key" do
      create(:model, rsi_focus: "Heavy Fighter", sc_role: "Multi-Role / Stealth Fighter")

      assert_empty UnplacedFoci.call
    end

    test "reports the parts to the admins who look after ships" do
      admin = create(:admin_user, resource_access: [:models])
      create(:model, name: "Vulture", rsi_focus: "Escort")

      UnplacedFoci.report

      notification = AdminNotification.find_by(admin_user: admin, notification_type: "unplaced_foci")
      assert_equal "warning", notification.severity
      assert_includes notification.body, "### escort"
      assert_includes notification.body, "- **Vulture** (ship matrix: \"Escort\")"
    end

    test "a report that cannot be delivered does not raise into the load" do
      create(:model, rsi_focus: "Escort")
      AdminReport.stubs(:deliver).raises(Octokit::TooManyRequests)
      Appsignal.expects(:report_error).once

      assert_nothing_raised { UnplacedFoci.report }
    end

    test "reports nothing when every part has a key" do
      create(:model, rsi_focus: "Gunship")
      AdminReport.expects(:deliver).never

      UnplacedFoci.report
    end
  end
end
