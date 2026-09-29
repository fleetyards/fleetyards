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
  // The 3D view is open. Only then is the viewer fetched: the holo is being
  // downloaded for it anyway, and a page view costs nothing extra.
  active?: boolean;
};

const props = withDefaults(defineProps<Props>(), { active: false });

const { t } = useI18n();

const { displayAlert } = useAppNotifications();

const viewer = shallowRef<ModelViewerElement>();

const holoUrl = computed(() => props.model.media.holo?.url);

// Only a holo exported in meters can be placed at true size.
const candidate = computed(
  () =>
    props.active && !!holoUrl.value && !!props.model.holoToScale && mayHaveAr(),
);

// Counts preparations, so one that finishes after a newer one started (another
// ship's holo) is thrown away rather than replacing the current viewer.
let preparation = 0;

const prepare = async () => {
  const current = ++preparation;

  viewer.value?.remove();
  viewer.value = undefined;

  if (!candidate.value || !holoUrl.value) {
    return;
  }

  const prepared = await prepareAr(holoUrl.value).catch(() => undefined);

  if (current !== preparation) {
    prepared?.remove();
    return;
  }

  viewer.value = prepared;
};

onMounted(prepare);

watch([holoUrl, () => props.active], prepare);

onBeforeUnmount(() => {
  preparation += 1;
  viewer.value?.remove();
});

// Straight from the tap, without awaiting anything first: the AR viewers only
// open from a user gesture.
const open = () => {
  viewer.value?.activateAR().catch(() => {
    displayAlert({ text: t("messages.error.default") });
  });
};
</script>

<template>
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
</template>
