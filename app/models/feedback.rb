# frozen_string_literal: true

class Feedback < ApplicationRecord
  include AASM

  paginates_per 24

  MESSAGE_MAX_LENGTH = 5000

  belongs_to :user
  belongs_to :resolved_by, class_name: "AdminUser", optional: true

  validates :message, presence: true, length: {maximum: MESSAGE_MAX_LENGTH}
  validates :page_path, length: {maximum: 2048}
  # Only when it is set: a flag that graduates leaves the registry, and its old
  # feedback still has to be resolvable.
  validates :feature_name, inclusion: {in: ->(_) { FeatureFlags::Registry.current.names }},
    allow_nil: true, if: :feature_name_changed?

  normalizes :feature_name, :page_path, with: ->(value) { value.presence }

  after_create_commit :notify_admins

  aasm timestamps: true, whiny_transitions: false do
    state :open, initial: true
    state :resolved

    event :resolve do
      transitions from: :open, to: :resolved
    end

    event :reopen do
      before { assign_attributes(resolved_by: nil, resolved_at: nil) }
      transitions from: :resolved, to: :open
    end
  end

  def self.ransackable_attributes(_auth_object = nil)
    %w[aasm_state feature_name message created_at]
  end

  def self.ransackable_associations(_auth_object = nil)
    %w[user]
  end

  # One row rather than one per message, so a busy day rewrites it instead of
  # filling every admin's inbox. It names no count: resolving does not touch
  # it, so a count would go stale.
  #
  # The feedback is saved by then, so a failure here must not answer the
  # request with an error that invites sending it again.
  private def notify_admins
    AdminNotification.notify!(
      type: :feedback,
      title: "New feedback",
      body: "Most recent from #{user.username}#{" about #{feature_name}" if feature_name}",
      severity: :info,
      link: "/feedback?aasmStateEq=open",
      record: self,
      dedupe_key: "feedback"
    )
  rescue => e
    Appsignal.report_error(e)
  end
end
