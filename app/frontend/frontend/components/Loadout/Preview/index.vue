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
  // `stage` is the inline holo filling the box it is put in, with the holo's
  // controls, and opens full screen; `backdrop` fills the box too, still and
  // closer, as a see-through hologram in the angled render's pose.
  variant?: "inline" | "stage" | "backdrop";
  // A backdrop turned by the viewer, with the holo's controls.
  interactive?: boolean;
  // A backdrop the wheel zooms rather than scrolling past.
  zoomable?: boolean;
  // A part on the holo answers the pointer with its slot's path.
  pickable?: boolean;
  testId?: string;
};

const props = withDefaults(defineProps<Props>(), {
  slots: undefined,
  variant: "inline",
  interactive: false,
  zoomable: false,
  pickable: false,
  testId: "loadout-preview",
});

const emit = defineEmits<{
  available: [available: boolean];
  // Settled that no holo is coming, so a caller can bring its picture in.
  absent: [absent: boolean];
  select: [path: string];
  point: [path: string | undefined];
}>();

// The pose of a ship's angled render: from ahead on its port side and well
// above, the nose towards the lower left. The export faces -Z.
const ANGLED_AZIMUTH = -135;
const ANGLED_ELEVATION = 35;

// The editor's backdrop fades in over the left of its frame, under the
// controls (LoadoutModal's mask): the ship is fitted beside them, and needs
// little room besides.
const BACKDROP_INSET = 0.45;
const BACKDROP_PADDING = 1.1;

// The inline holo's own low look, framed to the ship rather than to the
// circle it turns through, so a larger box shows a larger ship.
const INLINE_ELEVATION = 6;

const HoloViewer = defineAsyncComponent(
  () => import("@/shared/components/HoloViewer/index.vue"),
);

const viewer = ref<InstanceType<typeof HoloViewer>>();

const enableFullscreen = () => viewer.value?.enableFullscreen();

defineExpose({ enableFullscreen });

const { isFeatureEnabled } = useFeatures();

const mobile = useMobile();

const enabled = computed(
  () =>
    isFeatureEnabled(FeatureFlagName.LOADOUT_PREVIEW) &&
    !!props.modelSlug &&
    !mobile.value,
);

const {
  data: preview,
  isError,
  isSuccess,
} = useModelLoadoutPreview(() => props.modelSlug, {
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

const absent = computed(
  () =>
    !enabled.value ||
    isError.value ||
    (isSuccess.value && !holoModel.value) ||
    unavailable.value,
);

watch(available, (value) => emit("available", value), { immediate: true });

watch(absent, (value) => emit("absent", value), { immediate: true });

// Taken away by its caller, it shows nothing either, and the caller's picture
// has to come back.
onBeforeUnmount(() => {
  emit("available", false);
  emit("absent", true);
});
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
      :zoomable="interactive && zoomable"
      :contain-inset="BACKDROP_INSET"
      :contain-padding="BACKDROP_PADDING"
      contain
      hologram
      on-demand
      :pickable="pickable"
      @unavailable="unavailable = true"
      @loaded="loaded = true"
      @mount-select="emit('select', $event)"
      @mount-point="emit('point', $event)"
    />
    <HoloViewer
      v-else-if="variant === 'stage'"
      ref="viewer"
      :models="[holoModel]"
      :elevation="INLINE_ELEVATION"
      contain
      inline
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

  &--stage {
    --holo-viewer-inline-max-height: none;

    height: 100%;
  }

  &--backdrop {
    height: 100%;
  }
}
</style>
