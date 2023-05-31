import FleetyardsView from "@/embed/FleetyardsView.vue";
import ApiClient from "@/embed/api/client";
import store from "@/embed/lib/Store";
import I18nPlugin from "@/frontend/lib/I18n";
import "@/frontend/plugins/LazyLoad";
import VTooltip from "v-tooltip";
import Vue from "vue";

Vue.use(ApiClient);
Vue.use(I18nPlugin);

Vue.config.productionTip = false;

VTooltip.enabled = window.innerWidth > 768;
Vue.use(VTooltip, {
  defaultContainer: "#fleetyards-view",
});

window.FleetYardsFleetchart = null;

setTimeout(() => {
  if (store.state.storeVersion !== window.STORE_VERSION) {
    console.info("Updating Store Version and resetting Store");

    store.dispatch("reset");
    store.commit("setStoreVersion", window.STORE_VERSION);
  }

  // eslint-disable-next-line no-undef
  const config = window.FleetYardsFleetchartConfig || {};

  // eslint-disable-next-line no-new
  window.FleetYardsFleetchart = new Vue({
    el: "#fleetyards-view",
    store,
    data: function () {
      return {
        ships: config.ships || [],
        users: config.users || [],
        fleetId: config.fleetId || config.fleetID || null, // fleetID is deprecated, please use fleetId
        groupedButton: config.groupedButton || false,
        fleetchartSlider: config.fleetchartSlider || false,
        frontendEndpoint: window.FRONTEND_ENDPOINT,
      };
    },
    methods: {
      updateShips(ships) {
        const fleetview = (this.$children || [])[0];
        if (fleetview) {
          fleetview.updateShips(ships);
        }
      },

      updateUsers(users) {
        const fleetview = (this.$children || [])[0];
        if (fleetview) {
          fleetview.updateUsers(users);
        }
      },

      updateFleet(fleetID) {
        const fleetview = (this.$children || [])[0];
        if (fleetview) {
          fleetview.updateFleet(fleetID);
        }
      },
    },
    render: (h) => h(FleetyardsView),
  });
}, 2000);
