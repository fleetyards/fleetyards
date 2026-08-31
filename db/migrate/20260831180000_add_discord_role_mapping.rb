# frozen_string_literal: true

# Maps Fleetyards fleet roles onto Discord roles.
#
# Two separate things, deliberately:
#
# - `fleet_notification_settings.discord_member_role_id` is the "verified
#   member" role: one role for anyone who linked their account and is an
#   accepted member, independent of rank.
# - `fleet_roles.discord_role_id` maps one rank to one Discord role.
#
# Both are nullable and both are opt-in. The sync only ever touches role ids
# that appear in one of these two columns, so a role the fleet manages by hand
# in Discord is never removed by us.
class AddDiscordRoleMapping < ActiveRecord::Migration[8.1]
  def change
    add_column :fleet_notification_settings, :discord_member_role_id, :string
    add_column :fleet_roles, :discord_role_id, :string
  end
end
