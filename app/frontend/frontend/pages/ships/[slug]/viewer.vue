<script lang="ts">
export default {
  name: "ShipViewerPage",
};
</script>

<script lang="ts" setup>
import { type Model } from "@/services/fyApi";
import { useComlink } from "@/shared/composables/useComlink";
import { useModelsStore } from "@/frontend/stores/models";
import { storeToRefs } from "pinia";
import {
  modelStateHolo,
  modelStateMetrics,
  useModelStates,
} from "@/frontend/composables/useModelStates";
import { useI18n } from "@/shared/composables/useI18n";
import { useMetaInfo } from "@/shared/composables/useMetaInfo";

type Props = {
  model: Model;
};

const props = defineProps<Props>();

const { t } = useI18n();

const { updateMetaInfo } = useMetaInfo();

const metaTitle = computed(() => {
  if (!props.model) {
    return undefined;
  }

  return t("title.shipViewer", {
    name: props.model.name,
  });
});

onMounted(() => {
  updateMetaInfo({
    title: metaTitle.value,
  });
});

watch(
  () => props.model,
  () => updateMetaInfo({ title: metaTitle.value }),
);

const comlink = useComlink();

const { modelState } = storeToRefs(useModelsStore());

const { resolveState } = useModelStates(() => props.model);

// Popped out of the ship page, so it opens on the state that page was left on.
const holoModel = computed(() => {
  const state = resolveState(modelState.value);

  return {
    path: modelStateHolo(props.model, state)?.url,
    length: modelStateMetrics(props.model, state).fleetchartLength,
  };
});

const openModal = () => {
  comlink.emit("open-modal", {
    component: () => import("@/shared/components/HoloViewer/Modal/index.vue"),
    fullscreen: true,
    props: {
      models: [holoModel.value],
      backRoute: {
        name: "ship",
        params: { slug: props.model.slug },
      },
    },
  });
};

onMounted(() => {
  openModal();
});
</script>
