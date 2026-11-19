# frozen_string_literal: true

class Feedback < ApplicationRecord
  include AASM

  paginates_per 24

  MESSAGE_MAX_LENGTH = 5000

  belongs_to :user
  belongs_to :resolved_by, class_name: "AdminUser", optional: true

  validates :message, presence: true, length: {maximum: MESSAGE_MAX_LENGTH}
  validates :page_path, length: {maximum: 2048}
  validates :feature_name, inclusion: {in: ->(_) { FeatureFlags::Registry.current.names }}, allow_nil: true

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

  # One row for the open queue rather than one per message, so a busy day
  # updates a count instead of filling every admin's inbox.
  private def notify_admins
    waiting = self.class.open.count

    AdminNotification.notify!(
      type: :feedback,
      title: "#{waiting} open #{"feedback message".pluralize(waiting)}",
      body: "Most recent from #{user.username}#{" about #{feature_name}" if feature_name}",
      severity: :info,
      link: "/feedback?aasmStateEq=open",
      record: self,
      dedupe_key: "feedback"
    )
  end
end
