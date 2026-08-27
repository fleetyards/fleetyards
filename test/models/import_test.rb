# frozen_string_literal: true

# == Schema Information
#
# Table name: imports
#
#  id            :uuid             not null, primary key
#  aasm_state    :string
#  failed_at     :datetime
#  finished_at   :datetime
#  import_data   :text
#  info          :text
#  input         :jsonb
#  output        :jsonb
#  started_at    :datetime
#  type          :string
#  version       :string
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  admin_user_id :uuid
#  user_id       :uuid
#
# Indexes
#
#  index_imports_on_aasm_state_and_type  (aasm_state,type)
#  index_imports_on_admin_user_id        (admin_user_id)
#  index_imports_on_type                 (type)
#
# Foreign Keys
#
#  fk_rails_...  (admin_user_id => admin_users.id)
#
require "test_helper"

class ImportTest < ActiveSupport::TestCase
  # Import subclasses that keep the base #notify_admin broadcast every state
  # transition to admins over ImportsChannel, which serialises them via
  # #to_jbuilder_hash. That renders a per-type jbuilder partial whose path is
  # derived from the class name, so a missing partial only surfaces at runtime
  # as an ActionView::MissingTemplate in the broadcast processor. Render each
  # broadcasting type here so a new subclass without a partial fails the build.
  def broadcasting_import_types
    Rails.application.eager_load!
    Import.descendants.select do |klass|
      klass.instance_method(:notify_admin).owner == Import
    end
  end

  test "broadcasting import types are detected" do
    types = broadcasting_import_types

    assert_includes types, Imports::ModulesImport
    assert_includes types, Imports::PaintsImport
    assert_includes types, Imports::ModelsImport
    refute_includes types, Imports::HangarImport, "hangar imports must not broadcast"
    refute_includes types, Imports::HangarSync, "hangar syncs must not broadcast"
  end

  test "every broadcasting import type renders its jbuilder partial" do
    broadcasting_import_types.each do |klass|
      record = klass.new
      record.save!(validate: false)

      json = JSON.parse(record.to_jbuilder_json)

      assert_equal klass.name, json["type"]
      assert json["id"].present?, "#{klass} rendered without an id"
    end
  end

  test "a finished import tells the notification center" do
    admin_user = create(:admin_user, resource_access: [:imports])
    AdminNotificationsChannel.stubs(:broadcast_to)
    ImportsChannel.stubs(:broadcast_to)

    record = create(:import, type: "Imports::ModelImport")
    record.start!
    record.finish!

    notification = AdminNotification.find_by(admin_user:, notification_type: "import_run")

    assert_not_nil notification
    assert_equal "info", notification.severity
    assert_includes notification.title, "finished"
  end

  test "a failed import carries its error at error severity" do
    admin_user = create(:admin_user, resource_access: [:imports])
    AdminNotificationsChannel.stubs(:broadcast_to)
    ImportsChannel.stubs(:broadcast_to)

    record = create(:import, type: "Imports::ModelImport")
    record.start!
    record.update!(info: "RSI returned 502")
    record.fail!

    notification = AdminNotification.find_by(admin_user:, notification_type: "import_run")

    assert_equal "error", notification.severity
    assert_equal "RSI returned 502", notification.body
  end

  # Otherwise every paints run lands twice: once as the report with the missing
  # models in it, once as a line saying it finished.
  test "an import whose job files its own report stays quiet on success" do
    create(:admin_user, resource_access: [:imports])
    AdminNotificationsChannel.stubs(:broadcast_to)
    ImportsChannel.stubs(:broadcast_to)

    record = create(:import, type: "Imports::PaintsImport")
    record.start!
    record.finish!

    assert_equal 0, AdminNotification.where(notification_type: "import_run").count
  end

  test "an import whose job files its own report still reports a failure" do
    create(:admin_user, resource_access: [:imports])
    AdminNotificationsChannel.stubs(:broadcast_to)
    ImportsChannel.stubs(:broadcast_to)

    record = create(:import, type: "Imports::PaintsImport")
    record.start!
    record.fail!

    assert_equal 1, AdminNotification.where(notification_type: "import_run").count
  end

  test "an import a user owns is not admin news" do
    create(:admin_user, resource_access: [:imports])
    AdminNotificationsChannel.stubs(:broadcast_to)
    ImportsChannel.stubs(:broadcast_to)

    record = create(:import, type: "Imports::ModelImport", user: create(:user))
    record.start!
    record.finish!

    assert_equal 0, AdminNotification.where(notification_type: "import_run").count
  end

  test "notify_admin broadcasts a renderable payload to admins" do
    create(:admin_user)
    record = create(:import, :modules_import)

    payload = nil
    ImportsChannel.expects(:broadcast_to).at_least_once.with do |_admin, message|
      payload = message
      true
    end

    record.notify_admin

    assert_equal record.id, payload["id"]
    assert_equal "Imports::ModulesImport", payload["type"]
  end
end
