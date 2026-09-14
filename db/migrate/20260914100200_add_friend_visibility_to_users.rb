# frozen_string_literal: true

# Opening a hangar, a wishlist or the stats to friends without opening them to
# the internet.
#
# **A sibling boolean per surface rather than a three-valued enum.**
# `public_hangar` and its siblings are booleans in the public OpenAPI schema, on
# `/users/me`, and in the admin payload; turning them into enums is a breaking
# schema change, and this branch is already stacked. So each surface gains a
# second column and the rule is stated once:
#
#   public on            -> everyone, and the friend column is not consulted
#   public off, friend on -> friends
#   both off             -> nobody
#
# Which is a three-valued enum spelled in two booleans, and that is the honest
# description of the trade. What it buys is that no existing value changes
# meaning and no existing client breaks. Consolidating them belongs in a
# deliberate breaking release, all five at once rather than one at a time.
#
# All three default to false: a relationship never opens anything by itself.
# `public_hangar` already defaults to true, so for most accounts nothing changes
# at all -- these matter precisely to the people who turned that one off, who
# are the people who asked for this.
class AddFriendVisibilityToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :friends_hangar, :boolean, null: false, default: false
    add_column :users, :friends_hangar_stats, :boolean, null: false, default: false
    add_column :users, :friends_wishlist, :boolean, null: false, default: false
  end
end
