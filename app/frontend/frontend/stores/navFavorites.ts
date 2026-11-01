import { defineStore } from "pinia";

type NavFavoritesState = {
  // Kept here only while nobody is signed in. A signed-in account keeps its
  // list on the server, under `currentUser.navFavorites`, so it follows the
  // reader to every device.
  guestKeys: string[];
};

export const useNavFavoritesStore = defineStore("navFavorites", {
  state: (): NavFavoritesState => ({
    guestKeys: [],
  }),
  persist: {
    pick: ["guestKeys"],
  },
});
