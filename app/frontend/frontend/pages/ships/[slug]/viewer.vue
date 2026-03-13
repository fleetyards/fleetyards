<script lang="ts">
export default {
  name: "ShipViewerPage",
};
</script>

<script lang="ts" setup>
import { type Model } from "@/services/fyApi";
import { useComlink } from "@/shared/composables/useComlink";
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

const holoModel = computed(() => {
  return {
    path: props.model.media.holo?.url,
    length: props.model.metrics.fleetchartOffsetLength,
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
