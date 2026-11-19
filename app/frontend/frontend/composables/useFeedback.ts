import { storeToRefs } from "pinia";
import type { FeatureFlagName } from "@/services/fyApi";
import { useComlink } from "@/shared/composables/useComlink";
import { useSessionStore } from "@/frontend/stores/session";
import { OPEN_FEEDBACK, type OpenFeedback } from "@/shared/utils/BetaFeatures";

export const useFeedback = () => {
  const comlink = useComlink();
  const route = useRoute();
  const { isAuthenticated } = storeToRefs(useSessionStore());

  const openFeedback: OpenFeedback = (feature?: FeatureFlagName) => {
    comlink.emit("open-modal", {
      component: () => import("@/frontend/components/FeedbackModal/index.vue"),
      props: { feature, pagePath: route.path },
    });
  };

  const provideFeedback = () => {
    provide(
      OPEN_FEEDBACK,
      computed(() => (isAuthenticated.value ? openFeedback : undefined)),
    );
  };

  return { openFeedback, provideFeedback };
};
