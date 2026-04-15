# frozen_string_literal: true

class AddRecordToNotifications < ActiveRecord::Migration[7.2]
  def change
    add_reference :notifications, :record, polymorphic: true, type: :uuid, index: true
  end
end
