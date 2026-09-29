<script lang="ts">
export default {
  name: "ViewInArBtn",
};
</script>

<script lang="ts" setup>
import Btn from "@/shared/components/base/Btn/index.vue";
import { useI18n } from "@/shared/composables/useI18n";
import { useAppNotifications } from "@/shared/composables/useAppNotifications";
import {
  mayHaveAr,
  prepareAr,
  type ModelViewerElement,
} from "@/frontend/utils/arViewer";
import type { Model } from "@/services/fyApi";

type Props = {
  model: Model;
};

const props = defineProps<Props>();

const { t } = useI18n();

const { displayAlert } = useAppNotifications();

const host = ref<HTMLElement | null>(null);

const viewer = shallowRef<ModelViewerElement>();

const holoUrl = computed(() => props.model.media.holo?.url);

// Only a holo exported in meters can be placed at true size.
const candidate = computed(
  () => !!holoUrl.value && !!props.model.holoToScale && mayHaveAr(),
);

const prepare = async () => {
  viewer.value?.remove();
  viewer.value = undefined;

  if (!candidate.value || !holoUrl.value || !host.value) {
    return;
  }

  try {
    viewer.value = await prepareAr(holoUrl.value, host.value);
  } catch {
    viewer.value = undefined;
  }
};

onMounted(prepare);

watch(holoUrl, prepare);

onBeforeUnmount(() => viewer.value?.remove());

// Straight from the tap, without awaiting anything first: the AR viewers only
// open from a user gesture.
const open = () => {
  viewer.value?.activateAR().catch(() => {
    displayAlert({ text: t("messages.error.default") });
  });
};
</script>

<template>
  <span ref="host" class="view-in-ar">
    <Btn
      v-if="viewer"
      v-tooltip="t('labels.viewInArHint')"
      :aria-label="t('labels.viewInArHint')"
      data-test="view-in-ar"
      @click="open"
    >
      <i class="fa-light fa-cube" />
      {{ t("labels.viewInAr") }}
    </Btn>
  </span>
</template>

<style lang="scss" scoped>
.view-in-ar {
  display: contents;
}
</style>
