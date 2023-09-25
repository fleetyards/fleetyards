<template>
  <div v-if="hasImages" class="fleetchart-views">
    <div>
      <img v-if="fleetchartImageAngled" :src="fleetchartImageAngled" />
    </div>
    <div>
      <img v-if="fleetchartImageTop" :src="fleetchartImageTop" />
    </div>
    <div class="small">
      <img v-if="fleetchartImageFront" :src="fleetchartImageFront" />
    </div>
    <div>
      <img v-if="fleetchartImageSide" :src="fleetchartImageSide" />
    </div>
  </div>
</template>

<script lang="ts" setup>
import { useMobile } from "@/shared/composables/useMobile";
import type { Model } from "@/services/fyApi";

type Props = {
  model: Model;
};

const props = defineProps<Props>();

const mobile = useMobile();

const hasImages = computed(() => {
  return (
    fleetchartImageAngled.value ||
    fleetchartImageFront.value ||
    fleetchartImageTop.value ||
    fleetchartImageSide.value
  );
});

const fleetchartImageAngled = computed(() => {
  if (props.model.media.angledViewColored) {
    if (mobile.value) {
      return props.model.media.angledViewColored.medium;
    }

    return props.model.media.angledViewColored.large;
  }

  if (mobile.value && props.model.media.angledView) {
    return props.model.media.angledView.medium;
  }

  return props.model.media.angledView?.large;
});

const fleetchartImageFront = computed(() => {
  if (props.model.media.frontViewColored) {
    if (mobile.value) {
      return props.model.media.frontViewColored.medium;
    }

    return props.model.media.frontViewColored.large;
  }

  if (mobile.value && props.model.media.frontView) {
    return props.model.media.frontView.medium;
  }

  return props.model.media.frontView?.large;
});

const fleetchartImageTop = computed(() => {
  if (props.model.media.topViewColored) {
    if (mobile.value) {
      return props.model.media.topViewColored.medium;
    }

    return props.model.media.topViewColored.large;
  }

  if (mobile.value && props.model.media.topView) {
    return props.model.media.topView.medium;
  }

  return props.model.media.topView?.large;
});

const fleetchartImageSide = computed(() => {
  if (props.model.media.sideViewColored) {
    if (mobile.value) {
      return props.model.media.sideViewColored.medium;
    }

    return props.model.media.sideViewColored.large;
  }

  if (mobile.value && props.model.media.sideView?.medium) {
    return props.model.media.sideView.medium;
  }

  return props.model.media.sideView?.large;
});
</script>

<script lang="ts">
export default {
  name: "ModelsFleetchartImages",
};
</script>

<style scoped lang="scss">
@import "index.scss";
</style>
