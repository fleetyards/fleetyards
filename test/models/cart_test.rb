# frozen_string_literal: true

require "test_helper"

class CartTest < ActiveSupport::TestCase
  setup do
    @user = create(:user)
  end

  test "starts a list for the first add" do
    cart = Cart.active_for!(@user)

    assert_equal ["Shopping list", true], [cart.name, cart.active?]
  end

  test "names the first list in the user's language" do
    @user.update!(locale: "de")

    assert_equal "Einkaufsliste", Cart.active_for!(@user).name
  end

  test "picks the most recent list back up when none is active" do
    create(:cart, user: @user, active: false, updated_at: 2.days.ago)
    recent = create(:cart, user: @user, active: false, updated_at: 1.hour.ago)

    assert_equal recent, Cart.active_for!(@user)
    assert recent.reload.active?
  end

  test "keeps one active list per user" do
    first = create(:cart, user: @user)
    second = create(:cart, user: @user, active: false)

    second.activate!

    assert_not first.reload.active?
    assert second.reload.active?
  end

  test "hands active to the most recent list left when the active one goes" do
    older = create(:cart, user: @user, active: false, updated_at: 2.days.ago)
    newer = create(:cart, user: @user, active: false, updated_at: 1.hour.ago)
    active = create(:cart, user: @user)

    active.destroy_and_reactivate!

    assert newer.reload.active?
    assert_not older.reload.active?
  end

  test "names are unique per user" do
    create(:cart, user: @user, name: "Mining run")

    assert_not build(:cart, user: @user, name: "Mining run", active: false).valid?
    assert build(:cart, name: "Mining run").valid?
  end

  test "stops at the per-user limit" do
    now = Time.current
    Cart.insert_all(Array.new(Cart::MAX_PER_USER) do |index|
      {user_id: @user.id, name: "List #{index}", active: false, created_at: now, updated_at: now}
    end)
    cart = build(:cart, user: @user, active: false)

    assert_not cart.valid?
    assert cart.errors.added?(:base, :cart_list_limit_reached, count: Cart::MAX_PER_USER)
  end

  test "takes its lines with it" do
    cart_item = create(:cart_item, user: @user)

    cart_item.cart.destroy!

    assert_not CartItem.exists?(cart_item.id)
  end

  test "an unused name keeps its full length, and only a numbered one is cut" do
    name = "A" * 64

    assert_equal name, Cart.unused_name(@user, name)

    create(:cart, user: @user, name:)

    assert_equal "#{"A" * 56} (2)", Cart.unused_name(@user, name)
  end
end
