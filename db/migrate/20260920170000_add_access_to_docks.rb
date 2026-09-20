# frozen_string_literal: true

# How a vehicle or a ship gets into the berth, which the schema has never been
# able to say. It is not part of the fit check and is not meant to be: a car can
# be tractor-beamed into a hangar, it is merely awful, and "possible but
# awkward" is not something a dimension comparison can express. It belongs on
# the label, next to the measurements.
#
# Nullable, because most berths have not been looked at yet and "we do not know"
# is a different statement from "you will need a tractor beam".
class AddAccessToDocks < ActiveRecord::Migration[8.1]
  def change
    add_column :docks, :access, :integer
  end
end
