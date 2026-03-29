<script lang="ts">
export default {
  name: "BasePanelBgImage",
};
</script>

<script lang="ts" setup>
import { useLazyBackground } from "@/shared/composables/useLazyBackground";

type Props = {
  image: string;
  alignment?: "left" | "right";
  rounded?: "all" | "left" | "right" | "top" | "bottom";
};

const props = withDefaults(defineProps<Props>(), {
  alignment: undefined,
  rounded: "all",
});

const target = ref<HTMLElement | null>(null);
const imageSrc = computed(() => props.image);

const { isLoaded } = useLazyBackground(target, imageSrc);
</script>

<template>
  <div
    ref="target"
    class="panel-bg"
    :class="{
      'panel-bg-rounded': rounded === 'all',
      'panel-bg-rounded-left': rounded === 'left',
      'panel-bg-rounded-right': rounded === 'right',
      'panel-bg-rounded-top': rounded === 'top',
      'panel-bg-rounded-bottom': rounded === 'bottom',
      'panel-bg-align-left': alignment === 'left',
      'panel-bg-align-right': alignment === 'right',
    }"
  >
    <div v-if="!isLoaded" class="panel-bg__skeleton" />
  </div>
</template>

<style lang="scss" scoped>
@import "index";
</style>
