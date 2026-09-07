class AddPortTagsToHardpointsAndComponents < ActiveRecord::Migration[8.1]
  # What a port accepts is not only a type and a size. A port and the item that
  # fits it name a shared tag -- the Eclipse's ordnance port and its three bomb
  # racks all name `Eclipse_BombRack` -- and without those, a port that takes an
  # S3-S10 bomb launcher matches the Gladiator's and the Retaliator's racks just
  # as well as its own.
  #
  # Strings holding a serialised array, which is how `types` already stores the
  # same shape.
  def change
    add_column :hardpoints, :port_tags, :string
    add_column :hardpoints, :required_tags, :string
    add_column :hardpoints, :flags, :string

    add_column :components, :tags, :string
    add_column :components, :required_tags, :string

    # The items loader writes every component attribute to the build as well as
    # to the row, so a column the loader sets has to exist on both.
    add_column :component_builds, :tags, :string
    add_column :component_builds, :required_tags, :string
  end
end
