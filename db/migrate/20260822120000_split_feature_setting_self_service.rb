class SplitFeatureSettingSelfService < ActiveRecord::Migration[8.1]
  # self_service + self_service_scope encoded two independent facts in one
  # exclusive enum, and read as if it were three: a `fleet`-scoped flag was
  # listed on the personal surface *as well*, because a fleet flag keeps a
  # per-member preview. So `fleet` never meant "instead of user", it meant "as
  # well as user", and the pair could not express a fleet toggle without one.
  #
  # A boolean per surface says what the code actually reads.
  def up
    add_column :feature_settings, :self_service_user, :boolean, default: false, null: false
    add_column :feature_settings, :self_service_fleet, :boolean, default: false, null: false

    execute(<<~SQL)
      UPDATE feature_settings
      SET self_service_user = self_service,
          self_service_fleet = (self_service AND self_service_scope = 'fleet')
    SQL

    remove_column :feature_settings, :self_service
    remove_column :feature_settings, :self_service_scope
  end

  def down
    add_column :feature_settings, :self_service, :boolean, default: false, null: false
    add_column :feature_settings, :self_service_scope, :string, default: "user", null: false

    # A fleet-only toggle has no way back — the enum cannot say it, which is why
    # it was replaced. It reverts to the nearest thing the pair can express.
    execute(<<~SQL)
      UPDATE feature_settings
      SET self_service = (self_service_user OR self_service_fleet),
          self_service_scope = CASE WHEN self_service_fleet THEN 'fleet' ELSE 'user' END
    SQL

    remove_column :feature_settings, :self_service_user
    remove_column :feature_settings, :self_service_fleet
  end
end
