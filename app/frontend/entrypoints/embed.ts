import FleetyardsView from "@/embed/FleetyardsView.vue";
import "@/frontend/plugins/LazyLoad";
import pinia from "@/frontend/plugins/Pinia";
import VTooltip from "v-tooltip";

const app = createApp(FleetyardsView, {
  data: function () {
    return {
      ships: config.ships || [],
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

// eslint-disable-next-line no-undef
// @ts-expect-error defined on window
const config = fleetyards_config();

setTimeout(() => {
  app.mount("#fleetyards-view");
}, 2000);
