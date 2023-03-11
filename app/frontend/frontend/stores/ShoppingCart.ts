import { defineStore } from "pinia";
import { sortBy } from "@/frontend/lib/Helpers";
import type {
  TShoppingCartItem,
  TShoppingCartItemType,
} from "@/@types/models/ShoppingCartItem";

interface ShoppingCartState {
  items: TShoppingCartItem[];
}

const createShoppingCartItem = (
  newItem: any,
  type: TShoppingCartItemType
): TShoppingCartItem => {
  const soldAt = sortBy(
    (newItem.soldAt || []).map((item) => ({
      id: item.id,
      price: item.sellPrice,
      shopName: item.shop.name,
      shopSlug: item.shop.slug,
      stationName: item.shop.station.name,
      stationSlug: item.shop.station.slug,
    })),
    "price"
  );

  return {
    id: newItem.id,
    type,
    name: newItem.name,
    bestSoldAt: soldAt[0],
    soldAt,
    listedAt: (newItem.listedAt || []).map((item) => ({
      id: item.id,
      shopName: item.shop.name,
      shopSlug: item.shop.slug,
      stationName: item.shop.station.name,
      stationSlug: item.shop.station.slug,
    })),
    amount: 1,
  };
};

export const useShoppingCartStore = defineStore("ShoppingCart", {
  state: (): ShoppingCartState => ({
    items: [],
  }),
  actions: {
    reduceAmount(itemId: string) {
      const foundItem = this.items.find((cartItem) => cartItem.id === itemId);

      if (!foundItem || foundItem.amount <= 0) {
        return;
      }

      this.items = this.items.map((cartItem) => {
        if (cartItem.id !== foundItem.id) {
          return cartItem;
        }

        return {
          ...foundItem,
          amount: foundItem.amount - 1,
        };
      });
    },
    increaseAmount(itemId: string) {
      const foundItem = this.items.find((cartItem) => cartItem.id === itemId);

      if (!foundItem) {
        return;
      }

      this.items = this.items.map((cartItem) => {
        if (cartItem.id !== foundItem.id) {
          return cartItem;
        }

        return {
          ...foundItem,
          amount: foundItem.amount + 1,
        };
      });
    },
    add({ item, type }: { item: any; type: TShoppingCartItemType }) {
      const newItem = createShoppingCartItem(item, type);
      const foundItem = this.items.find((cartItem) => cartItem.id === item.id);

      if (foundItem) {
        this.items = this.items.map((cartItem) => {
          if (cartItem.id !== item.id) {
            return cartItem;
          }

          return {
            ...newItem,
            amount: foundItem.amount + 1,
          };
        });
      } else {
        this.items.push(newItem);
      }
    },
    update({ item, type }: { item: any; type: TShoppingCartItemType }) {
      const newItem = createShoppingCartItem(item, type);

      this.items = this.items.map((cartItem) => {
        if (cartItem.id !== newItem.id) {
          return cartItem;
        }

        return {
          ...newItem,
          amount: cartItem.amount,
        };
      });
    },
    remove(cartItemId: string) {
      this.items = this.items.filter((cartItem) => cartItem.id !== cartItemId);
    },
    clear() {
      this.items = [];
    },
  },
  persist: true,
});
