# frozen_string_literal: true

# The column held a path into the game files, which was only ever the parser's
# way of telling the loader which file to attach. The parsed records still
# carry it; the database does not need to.
class DropIconPathsNowTheImagesAreAttached < ActiveRecord::Migration[8.1]
  def change
    remove_column :commodities, :icon, :string
    remove_column :equipment, :icon, :string
  end
end
