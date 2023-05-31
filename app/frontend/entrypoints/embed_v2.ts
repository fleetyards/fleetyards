import FleetyardsView from "@/embed/FleetyardsView.vue";
import "@/frontend/plugins/LazyLoad";
import pinia from "@/frontend/plugins/Pinia";
import VTooltip from "v-tooltip";

export type FleetyardsEmbedConfig = {
  ships?: TModel[];
  users?: TUser[];
  fleetId?: string;
  /**
   * @deprecated fleetID is deprecated, please use fleetId
   */
  fleetID?: string;
  details?: boolean;
  fleetchart?: boolean;
  grouped?: boolean;
  groupedButton?: boolean;
  fleetchartSlider?: boolean;
  fleetchartScale?: number;
  fleetchartGrouped?: boolean;
};

declare global {
  interface Window {
    FleetYardsFleetchartConfig: FleetyardsEmbedConfig;
  }
}

const config = window.FleetYardsFleetchartConfig || {};

const app = createApp(FleetyardsView, {
  data: function () {
    return {
      ships: config.ships || [],
      users: config.users || [],
      fleetId: config.fleetId || config.fleetID || null,
      groupedButton: config.groupedButton || false,
      fleetchartSlider: config.fleetchartSlider || false,
      frontendEndpoint: window.FRONTEND_ENDPOINT,
    };
  },
});

app.use(pinia);

VTooltip.enabled = window.innerWidth > 768;
app.use(VTooltip, {
  defaultContainer: "#fleetyards-view",
});

setTimeout(() => {
  app.mount("#fleetyards-view");
}, 2000);
