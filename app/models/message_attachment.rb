# frozen_string_literal: true

class MessageAttachment < ApplicationRecord
  belongs_to :message
end
