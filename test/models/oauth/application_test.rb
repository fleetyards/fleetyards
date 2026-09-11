# frozen_string_literal: true

require "test_helper"

# == Schema Information
#
# Table name: oauth_applications
#
#  id               :uuid             not null, primary key
#  aasm_state       :string           default("pending"), not null
#  approved_at      :datetime
#  confidential     :boolean          default(TRUE), not null
#  name             :string           not null
#  owner_type       :string
#  redirect_uri     :text
#  rejected_at      :datetime
#  rejection_reason :text
#  scopes           :string           default(""), not null
#  secret           :string(512)      not null
#  uid              :string           not null
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#  owner_id         :uuid
#  reviewed_by_id   :uuid
#
# Indexes
#
#  index_oauth_applications_on_aasm_state               (aasm_state)
#  index_oauth_applications_on_owner_id_and_owner_type  (owner_id,owner_type)
#  index_oauth_applications_on_reviewed_by_id           (reviewed_by_id)
#  index_oauth_applications_on_uid                      (uid) UNIQUE
#
module Oauth
  class ApplicationTest < ActiveSupport::TestCase
    test "is pending until somebody approves it" do
      application = create(:oauth_application, :pending)

      assert_predicate application, :pending?
      assert_not application.usable_as_client?
    end

    test "approving makes it usable and stamps the time" do
      application = create(:oauth_application, :pending)

      application.approve

      assert application.save

      assert_predicate application, :approved?
      assert_not_nil application.approved_at
      assert application.usable_as_client?
    end

    test "rejecting without a reason is refused" do
      application = create(:oauth_application, :pending)

      application.reject

      assert_not application.save
      assert_includes application.errors.attribute_names, :rejection_reason
      assert_predicate application.reload, :pending?
    end

    test "rejecting with a reason records it" do
      application = create(:oauth_application, :pending)
      application.rejection_reason = "Redirect target is not under the stated domain"

      application.reject

      assert application.save

      assert_predicate application, :rejected?
      assert_not_nil application.rejected_at
      assert_not application.usable_as_client?
    end

    test "approving a rejected application clears the refusal" do
      application = create(:oauth_application, :rejected)

      application.approve

      assert application.save

      assert_predicate application, :approved?
      assert_nil application.rejection_reason
      assert_nil application.rejected_at
    end

    # Approval is granted for one redirect target and one set of scopes, so
    # moving either afterwards would carry a review nobody performed.
    test "changing the redirect target returns an approved application to review" do
      application = create(:oauth_application)

      application.update!(redirect_uri: "https://somewhere-else.example.com/callback")

      assert_predicate application.reload, :pending?
      assert_nil application.approved_at
      assert_not application.usable_as_client?
    end

    test "changing the scopes returns an approved application to review" do
      application = create(:oauth_application)

      application.update!(scopes: ["public", "hangar:write"])

      assert_predicate application.reload, :pending?
    end

    test "renaming an approved application leaves it approved" do
      application = create(:oauth_application)

      application.update!(name: "Renamed")

      assert_predicate application.reload, :approved?
    end

    test "a pending application reports itself for review" do
      admin_user = create(:admin_user, :super_admin)

      assert_difference -> { AdminNotification.where(admin_user:, notification_type: "oauth_application_review").count }, 1 do
        create(:oauth_application, :pending)
      end
    end

    test "an approved application reports nothing" do
      create(:admin_user, :super_admin)

      assert_no_difference -> { AdminNotification.where(notification_type: "oauth_application_review").count } do
        create(:oauth_application)
      end
    end

    test "rejects a vector logo" do
      application = build(:oauth_application)
      application.logo.attach(
        io: StringIO.new("<svg xmlns='http://www.w3.org/2000/svg'></svg>"),
        filename: "logo.svg",
        content_type: "image/svg+xml"
      )

      assert_not application.valid?
      assert_includes application.errors.attribute_names, :logo
    end
  end
end
