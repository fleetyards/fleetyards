<script lang="ts">
export default {
  name: "LoadoutPreview",
};
</script>

<script lang="ts" setup>
import {
  FeatureFlagName,
  type LoadoutSlot,
  useModelLoadoutPreview,
} from "@/services/fyApi";
import { loadoutMounts } from "@/frontend/utils/loadoutPreview";
import { useFeatures } from "@/frontend/composables/useFeatures";
import { useMobile } from "@/shared/composables/useMobile";

type Props = {
  modelSlug: string;
  // The fitting's slot tree; without one the stock ship is shown.
  slots?: LoadoutSlot[];
  testId?: string;
};

const props = withDefaults(defineProps<Props>(), {
  slots: undefined,
  testId: "loadout-preview",
});

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
</script>

<template>
  <div
    v-if="holoModel && !unavailable"
    class="loadout-preview"
    :data-test="testId"
  >
    <HoloViewer
      :models="[holoModel]"
      zoomable
      inline
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
