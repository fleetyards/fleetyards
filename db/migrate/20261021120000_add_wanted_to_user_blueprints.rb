# frozen_string_literal: true

# A marker can also say "I am after this one". Kept on the same row rather than
# in a table of its own: wanting and holding a recipe are exclusive states of
# one relation, so the unique pair already stops somebody both holding and
# wanting it, and acquiring a wanted recipe is an update rather than a move.
#
# Default false, so every marker written before this keeps meaning "held".
class AddWantedToUserBlueprints < ActiveRecord::Migration[8.1]
  def change
    add_column :user_blueprints, :wanted, :boolean, null: false, default: false
  end
end
