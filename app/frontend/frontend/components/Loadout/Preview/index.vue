<script lang="ts">
export default {
  name: "LoadoutPreview",
};
</script>

<script lang="ts" setup>
import { FeatureFlagName, useModelLoadoutPreview } from "@/services/fyApi";
import {
  loadoutMounts,
  type PreviewSlot,
} from "@/frontend/utils/loadoutPreview";
import { useFeatures } from "@/frontend/composables/useFeatures";
import { useMobile } from "@/shared/composables/useMobile";

type Props = {
  modelSlug: string;
  // The fitting's slot tree; without one the stock ship is shown.
  slots?: PreviewSlot[];
  testId?: string;
};

const props = withDefaults(defineProps<Props>(), {
  slots: undefined,
  testId: "loadout-preview",
});

const emit = defineEmits<{ available: [available: boolean] }>();

// The pose of a ship's angled render: from ahead on its port side and well
// above, the nose towards the lower left. The export faces -Z.
const ANGLED_AZIMUTH = -135;
const ANGLED_ELEVATION = 35;

const HoloViewer = defineAsyncComponent(
  () => import("@/shared/components/HoloViewer/index.vue"),
);

const { isFeatureEnabled } = useFeatures();

const mobile = useMobile();

const enabled = computed(
  () =>
    isFeatureEnabled(FeatureFlagName.LOADOUT_PREVIEW) &&
    !!props.modelSlug &&
    !mobile.value,
);

const { data: preview } = useModelLoadoutPreview(() => props.modelSlug, {
  query: { enabled },
});

const holoModel = computed(() => {
  const hull = preview.value?.holoHull;

  if (!enabled.value || !preview.value || !hull?.url) return undefined;

  return {
    path: hull.url,
    size: hull.size ?? undefined,
    mounts: loadoutMounts(preview.value, props.slots),
  };
});

// Without WebGL or a hull that loads there is nothing to show.
const unavailable = ref(false);

const available = computed(() => !!holoModel.value && !unavailable.value);

watch(available, (value) => emit("available", value), { immediate: true });
</script>

<template>
  <div
    v-if="available && holoModel"
    class="loadout-preview"
    :data-test="testId"
  >
    <!-- Not inline: that caps the canvas at an item hero's height, where this
    frame gives the ship its own. -->
    <HoloViewer
      :models="[holoModel]"
      :auto-rotate="false"
      :azimuth="ANGLED_AZIMUTH"
      :elevation="ANGLED_ELEVATION"
      zoomable
      @unavailable="unavailable = true"
    />
  </div>
</template>

<style lang="scss" scoped>
.loadout-preview {
  position: relative;
  width: 100%;
  aspect-ratio: 16 / 9;
  margin-bottom: 24px;
}
</style>
