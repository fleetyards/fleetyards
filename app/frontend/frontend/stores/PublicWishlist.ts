import { defineStore } from "pinia";

interface PublicWishlistState {
  perPage: number;
}

export const usePublicWishlistStore = defineStore("PublicWishlist", {
  state: (): PublicWishlistState => ({
    perPage: 30,
  }),
  actions: {
    updatePerPage(payload: number) {
      this.perPage = payload;
    },
  },
});
