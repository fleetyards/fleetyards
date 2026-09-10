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
  class Application < ApplicationRecord
    include ::Doorkeeper::Orm::ActiveRecord::Mixins::Application
    include AASM

    belongs_to :owner, polymorphic: true, optional: true
    belongs_to :reviewed_by, class_name: "AdminUser", optional: true

    encrypts :secret

    # Shown on the consent screen, so the person granting access can recognise
    # who is asking. `no_vector_image` is not optional on anything a user
    # uploads: an SVG can carry script, and this one is rendered to strangers.
    has_one_attached :logo
    validates :logo, no_vector_image: true

    # A refusal the owner cannot act on is worse than no answer at all, so the
    # reason is part of the transition rather than an optional note beside it.
    validates :rejection_reason, presence: true, if: :rejected?

    scope :pending_review, -> { where(aasm_state: "pending") }

    # Approval is granted for one redirect target and one set of scopes. Without
    # this, an application could be approved while harmless and then be pointed
    # somewhere else, carrying a review nobody performed. Model-level rather than
    # in the controller so no future write path can skip it.
    before_update :return_to_review,
      if: -> { approved? && (redirect_uri_changed? || scopes_changed?) }

    after_create_commit :report_for_review, if: :pending?

    # `whiny_transitions: false` matches the other state machines here, and
    # timestamps fill `approved_at` / `rejected_at`. Both events transition with
    # validation, so a reject without a reason fails rather than writing the
    # state and dropping the note.
    aasm timestamps: true, whiny_transitions: false do
      state :pending, initial: true
      state :approved
      state :rejected

      event :approve do
        transitions from: %i[pending rejected], to: :approved, after: :clear_rejection
      end

      event :reject do
        transitions from: %i[pending approved], to: :rejected
      end
    end

    def self.policy_class
      OauthApplicationPolicy
    end

    # What `allow_grant_flow_for_client` asks. Kept as a predicate rather than a
    # bare state comparison because the initializer is the one place a wrong
    # answer hands a stranger a working client.
    def usable_as_client?
      approved?
    end

    private def clear_rejection
      self.rejection_reason = nil
      self.rejected_at = nil
    end

    private def return_to_review
      self.aasm_state = "pending"
      self.approved_at = nil
    end

    # The operator finds out from the notification center rather than by
    # happening to open the admin page. `dedupe_key` on the record keeps a
    # re-edited application to one row in the inbox.
    private def report_for_review
      AdminNotification.notify!(
        type: :oauth_application_review,
        title: "OAuth application awaiting review: #{name}",
        body: owner.is_a?(User) ? "Registered by #{owner.username}" : nil,
        severity: :info,
        link: "/oauth-applications/#{id}",
        record: self,
        dedupe_key: "oauth_application_review:#{id}"
      )
    end
  end
end
