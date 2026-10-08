# frozen_string_literal: true

class Message < ApplicationRecord
  belongs_to :user, optional: true
  has_many :message_attachments, dependent: :destroy

  validates :email, :from_raw, :to, presence: true

  serialize :from_raw, coder: YAML
  serialize :to, coder: YAML
end
