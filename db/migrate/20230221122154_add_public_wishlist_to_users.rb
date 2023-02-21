class AddPublicWishlistToUsers < ActiveRecord::Migration[7.0]
  def change
    add_column :users, :public_wishlist, :boolean, default: false
  end
end
