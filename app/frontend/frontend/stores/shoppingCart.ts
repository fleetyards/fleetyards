import { defineStore } from "pinia";
import { sortBy } from "@/shared/utils/Array";
import type {
  SearchResultTypeEnum,
  Model,
  Component,
  Equipment,
  ModelModule,
  ModelPaint,
} from "@/services/fyApi";

export type ShoppingCartItemType =
  | Model
  | Component
  | Equipment
  | ModelModule
  | ModelPaint;

type ShoppingCartLocation = {
  id: string;
  price?: number;
  shopName: string;
  shopSlug: string;
  stationName: string;
  stationSlug: string;
};

export type ShoppingCartItem = {
  id: string;
  type: string;
  name: string;
  bestSoldAt: ShoppingCartLocation;
  soldAt: ShoppingCartLocation[];
  listedAt: ShoppingCartLocation[];
  amount: number;
};

interface ShoppingCartState {
  items: ShoppingCartItem[];
}

const createShoppingCartItem = (
  newItem: ShoppingCartItemType,
  type: SearchResultTypeEnum,
): ShoppingCartItem => {
  const soldAt = sortBy<ShoppingCartLocation>(
    (newItem.availability.soldAt || []).map((item) => ({
      id: item.id,
      price: item.prices.sellPrice,
      shopName: item.shop.name,
      shopSlug: item.shop.slug,
      stationName: item.shop.station.name,
      stationSlug: item.shop.station.slug,
    })),
    "price",
  );

  return {
    id: newItem.id,
    type,
    name: newItem.name,
    bestSoldAt: soldAt[0],
    soldAt,
    listedAt: (newItem.availability.listedAt || []).map((item) => ({
      id: item.id,
      shopName: item.shop.name,
      shopSlug: item.shop.slug,
      stationName: item.shop.station.name,
      stationSlug: item.shop.station.slug,
    })),
    amount: 1,
  };
};

export const useShoppingCartStore = defineStore("shoppingCart", {
  state: (): ShoppingCartState => ({
    items: [],
  }),
  getters: {},
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

      this.increaseItemAmount(foundItem);
    },

    increaseItemAmount(item: ShoppingCartItem) {
      this.items = this.items.map((cartItem) => {
        if (cartItem.id !== item.id) {
          return cartItem;
        }

        return {
          ...item,
          amount: item.amount + 1,
        };
      });
    },

    add(item: ShoppingCartItemType, type: SearchResultTypeEnum) {
      const foundItem = this.items.find((cartItem) => cartItem.id === item.id);

      if (foundItem) {
        this.increaseItemAmount(foundItem);
      } else {
        const newItem = createShoppingCartItem(item, type);
        this.items.push(newItem);
      }
    },

    update(item: ShoppingCartItemType, type: SearchResultTypeEnum) {
      const newItem = createShoppingCartItem(item, type);

      this.items.map((cartItem) => {
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
  persist: {
    paths: ["items"],
  },
});
