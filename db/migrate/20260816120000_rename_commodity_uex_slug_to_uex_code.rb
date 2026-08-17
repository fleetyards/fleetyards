class RenameCommodityUexSlugToUexCode < ActiveRecord::Migration[8.1]
  def change
    # UEX gives vehicles a slug but commodities only an id and a short code
    # ("GOLD"), so the column was named for a field that does not exist.
    rename_column :commodities, :uex_slug, :uex_code
  end
end
