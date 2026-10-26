# frozen_string_literal: true

# A list of catalogue items a fleet wants its members to buy, such as the
# standard kit or the uniform. It is published from one of a member's own cart
# lists and copied back into members' carts, where the trip planner prices it.
class FleetShoppingList < ApplicationRecord
  MAX_PER_FLEET = 50

  belongs_to :fleet, touch: true
  has_many :fleet_shopping_list_items, dependent: :delete_all

  # `squadron_only` narrows it to the squadrons named in `fleet_squadrons`;
  # see SquadronRestrictable.
  enum :visibility, {members_only: 0, officers_only: 1, squadron_only: 2}

  include SquadronRestrictable

  validates :name, presence: true, length: {maximum: 64}, uniqueness: {case_sensitive: false, scope: :fleet_id}
  validates :description, length: {maximum: 1000}, allow_blank: true
  validate :list_limit, on: :create

  AVAILABLE_PRIVILEGES = [
    "fleet:shopping_lists:read",
    "fleet:shopping_lists:create",
    "fleet:shopping_lists:update",
    "fleet:shopping_lists:delete",
    "fleet:shopping_lists:manage"
  ].freeze

  DEFAULT_PRIVILEGES = {
    admin: [],
    officer: ["fleet:shopping_lists:manage"],
    member: ["fleet:shopping_lists:read"]
  }.freeze

  OFFICER_PRIVILEGES = ["fleet:manage", "fleet:shopping_lists:manage"].freeze

  READ_PRIVILEGES = [*OFFICER_PRIVILEGES, "fleet:shopping_lists:read"].freeze

  def self.ransackable_attributes(_auth_object = nil)
    %w[name fleet_id visibility created_at updated_at]
  end

  def self.ransackable_associations(_auth_object = nil)
    []
  end

  # An officer reaches every list, whichever squadron it is held to. Also the
  # check on a write: nobody may save a list into a visibility that hides it
  # from themselves.
  def visible_to?(membership)
    return true if members_only?
    return false if membership.blank?
    return true if membership.has_access?(OFFICER_PRIVILEGES)

    squadron_only? && visible_to_squadrons_of?(membership)
  end

  # The lines become a copy of the cart's: item and quantity, never the pin,
  # which is one member's choice of shop.
  def replace_items_from!(cart)
    # Stamped a microsecond apart so the list keeps the cart's order: both the
    # trip plan and a copy read lines back by `created_at`.
    now = Time.current
    rows = cart.cart_items.order(:created_at).pluck(:item_type, :item_id, :quantity)
      .each_with_index.map do |(item_type, item_id, quantity), index|
        stamp = now + (index * 0.000001)
        {fleet_shopping_list_id: id, item_type:, item_id:, quantity:, created_at: stamp, updated_at: stamp}
      end

    transaction do
      fleet_shopping_list_items.delete_all
      FleetShoppingListItem.insert_all!(rows) if rows.any?
      touch
    end

    fleet_shopping_list_items.reset
  end

  # The lines whose item is still in the catalogue.
  def copyable_items
    fleet_shopping_list_items.includes(:item).order(:created_at).select(&:item)
  end

  # Adds every line to the cart, on top of what it already holds of the same
  # item. Raises ActiveRecord::RecordInvalid, leaving the cart as it was, when
  # a line would break the cart's limits.
  def copy_items_to!(cart, lines = copyable_items)
    existing = cart.cart_items.index_by { |cart_item| [cart_item.item_type, cart_item.item_id] }

    cart.transaction do
      lines.each do |line|
        cart_item = existing[[line.item_type, line.item_id]] ||
          cart.cart_items.new(item: line.item, quantity: 0)
        cart_item.quantity = [cart_item.quantity + line.quantity, CartItem::MAX_QUANTITY].min
        cart_item.save!
      end
    end
  end

  private def list_limit
    return if fleet.blank?
    return if fleet.fleet_shopping_lists.count < MAX_PER_FLEET

    errors.add(:base, :fleet_shopping_list_limit_reached, count: MAX_PER_FLEET)
  end
end
