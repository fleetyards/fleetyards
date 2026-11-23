<script lang="ts">
export default {
  name: "DressingRoomAvatarRenderer",
};
</script>

<script lang="ts" setup>
import HoloViewer from "@/shared/components/HoloViewer/index.vue";
import type { OutfitHoloModel } from "@/frontend/utils/dressingRoom";

type Props = {
  // Each figure to draw, in turn: one viewer at a time keeps the memory of a
  // second figure off the page.
  models: OutfitHoloModel[];
  azimuth?: number;
  elevation?: number;
};

const props = withDefaults(defineProps<Props>(), {
  azimuth: 180,
  elevation: 5,
});

const emit = defineEmits<{
  done: [portraits: (Blob | null)[]];
}>();

const index = ref(0);
const portraits: (Blob | null)[] = [];

const viewer = ref<InstanceType<typeof HoloViewer>>();

const current = computed(() => props.models[index.value]);

watch(
  viewer,
  async (instance) => {
    if (!instance) return;

    portraits.push(await instance.capturePortrait());

    if (index.value + 1 < props.models.length) {
      index.value += 1;
    } else {
      emit("done", portraits);
    }
  },
  { flush: "post" },
);
</script>

<template>
  <div class="avatar-renderer" aria-hidden="true">
    <HoloViewer
      v-if="current"
      ref="viewer"
      :key="`${index}:${current.path}`"
      :models="[current]"
      :azimuth="azimuth"
      :elevation="elevation"
      :auto-rotate="false"
      :controllable="false"
      contain
    />
  </div>
</template>

<style lang="scss" scoped>
.avatar-renderer {
  position: fixed;
  top: 0;
  left: -200vw;
  width: 640px;
  height: 640px;
  pointer-events: none;
}
</style>
