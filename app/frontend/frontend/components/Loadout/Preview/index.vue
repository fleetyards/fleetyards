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
  // `inline` turns slowly on its own, as the ship page's small holo does;
  // `backdrop` fills the box it is put in, still and closer, as a see-through
  // hologram in the angled render's pose.
  variant?: "inline" | "backdrop";
  // A backdrop turned and zoomed by the viewer, with the holo's controls.
  interactive?: boolean;
  testId?: string;
};

const props = withDefaults(defineProps<Props>(), {
  slots: undefined,
  variant: "inline",
  interactive: false,
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

// The hull on screen: until then a caller keeps its picture up.
const loaded = ref(false);

watch(
  () => holoModel.value?.path,
  () => {
    loaded.value = false;
    unavailable.value = false;
  },
);

const shown = computed(() => !!holoModel.value && !unavailable.value);

const available = computed(() => shown.value && loaded.value);

watch(available, (value) => emit("available", value), { immediate: true });

// Taken away by its caller, it shows nothing either, and the caller's picture
// has to come back.
onBeforeUnmount(() => emit("available", false));
</script>

<template>
  <div
    v-if="shown && holoModel"
    class="loadout-preview"
    :class="`loadout-preview--${variant}`"
    :data-test="testId"
  >
    <HoloViewer
      v-if="variant === 'backdrop'"
      :models="[holoModel]"
      :auto-rotate="false"
      :azimuth="ANGLED_AZIMUTH"
      :elevation="ANGLED_ELEVATION"
      :controllable="interactive"
      :zoomable="interactive"
      contain
      hologram
      on-demand
      @unavailable="unavailable = true"
      @loaded="loaded = true"
    />
    <HoloViewer
      v-else
      :models="[holoModel]"
      :controllable="false"
      inline
      @unavailable="unavailable = true"
      @loaded="loaded = true"
    />
  </div>
</template>

<style lang="scss" scoped>
.loadout-preview {
  position: relative;
  width: 100%;

  // The inline viewer's own cap.
  &--inline {
    height: 200px;
  }

  &--backdrop {
    height: 100%;
  }
}
</style>
