# frozen_string_literal: true

class Feedback < ApplicationRecord
  include AASM

  paginates_per 24

  MESSAGE_MAX_LENGTH = 5000

  belongs_to :user
  belongs_to :resolved_by, class_name: "AdminUser", optional: true

  has_many :replies, -> { order(:created_at) }, class_name: "FeedbackReply", dependent: :delete_all, inverse_of: :feedback

  validates :message, presence: true, length: {maximum: MESSAGE_MAX_LENGTH}
  validates :page_path, length: {maximum: 2048}
  # Only when it is set: a flag that graduates leaves the registry, and its old
  # feedback still has to be resolvable.
  validates :feature_name, inclusion: {in: ->(_) { FeatureFlags::Registry.current.names }},
    allow_nil: true, if: :feature_name_changed?

  normalizes :feature_name, :page_path, with: ->(value) { value.presence }

  after_create_commit :notify_admins
  after_update_commit :broadcast_change, if: :saved_change_to_aasm_state?

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

  # The payload each side's REST endpoint serves, so a page can take it as is.
  # A socket that is not there must not undo what was just committed.
  def broadcast_change
    FeedbackChannel.broadcast_to(user, render_payload("api/v1/feedbacks/show"))

    admin_payload = render_payload("admin/api/v1/feedbacks/show")
    AdminUser.find_each do |admin_user|
      next unless admin_user.has_access?(["feedback"])

      AdminFeedbackChannel.broadcast_to(admin_user, admin_payload)
    end
  rescue => e
    Rails.logger.error("Feedback broadcast failed for #{id}: #{e.message}")
  end

  private def render_payload(template)
    JSON.parse(
      ApplicationController.renderer.render(
        template:, assigns: {feedback: self}, formats: [:json], handlers: [:jbuilder]
      )
    )
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
