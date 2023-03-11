import Vue from "vue";
import { Component, Watch } from "vue-property-decorator";
import { Getter } from "vuex-class";
import HangarItemsCollection from "@/frontend/api/collections/HangarItems";
import WishlistItemsCollection from "@/frontend/api/collections/WishlistItems";

@Component<HangarItemsMixin>({})
export default class HangarItemsMixin extends Vue {
  @Getter("isAuthenticated", { namespace: "session" }) isAuthenticated;

  @Watch("$route")
  onRouteChange() {
    this.fetchHangarItems();
    this.fetchWishlistItems();
  }

  @Watch("isAuthenticated")
  onSessionChange() {
    this.fetchHangarItems();
    this.fetchWishlistItems();
  }

  created() {
    this.fetchHangarItems();
    this.fetchWishlistItems();
  }

  async fetchHangarItems() {
    if (!this.isAuthenticated) {
      return;
    }

    await this.$store.dispatch(
      "hangar/saveHangar",
      await HangarItemsCollection.findAll()
    );
  }

  async fetchWishlistItems() {
    if (!this.isAuthenticated) {
      return;
    }

    await this.$store.dispatch(
      "wishlist/saveHangar",
      await WishlistItemsCollection.findAll()
    );
  }
}
