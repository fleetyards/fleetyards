<script lang="ts">
export default {
  name: "ShipViewerPage",
};
</script>

<script lang="ts" setup>
import { type Model } from "@/services/fyApi";
import { useModelsStore } from "@/frontend/stores/models";
import { storeToRefs } from "pinia";
import { useModelStates } from "@/frontend/composables/useModelStates";
import { useHoloViewerPage } from "@/frontend/composables/useHoloViewerPage";
import { useI18n } from "@/shared/composables/useI18n";

type Props = {
  model: Model;
};

const props = defineProps<Props>();

const { t } = useI18n();

const route = useRoute();

const { modelState } = storeToRefs(useModelsStore());

const { resolveState } = useModelStates(() => props.model);

// Popped out of the ship page, so it opens on the state, and the textured
// holo and paint, that page was left on.
useHoloViewerPage({
  title: () => t("title.shipViewer", { name: props.model.name }),
  backRoute: () => ({ name: "ship", params: { slug: props.model.slug } }),
  modal: () => ({
    component: () => import("@/frontend/components/Models/HoloModal/index.vue"),
    fullscreen: true,
    props: {
      model: props.model,
      state: resolveState(modelState.value),
      textured: route.query.textured === "1",
      paintId:
        typeof route.query.paint === "string" ? route.query.paint : undefined,
    },
  }),
});
</script>
