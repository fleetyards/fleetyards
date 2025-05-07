<template>
  <div v-if="hasImages" class="fleetchart-views">
    <div>
      <img
        v-if="fleetchartImageAngled"
        :src="fleetchartImageAngled"
        :width="length > beam ? length : beam"
      />
    </div>
    <div>
      <img
        v-if="fleetchartImageTop"
        :src="fleetchartImageTop"
        :width="length"
      />
    </div>
    <div>
      <img
        v-if="fleetchartImageFront"
        :src="fleetchartImageFront"
        :width="beam"
      />
    </div>
    <div>
      <img
        v-if="fleetchartImageSide"
        :src="fleetchartImageSide"
        :width="length"
      />
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
      return props.model.media.angledViewColored.mediumUrl;
    }

    return props.model.media.angledViewColored.largeUrl;
  }

  if (mobile.value && props.model.media.angledView) {
    return props.model.media.angledView.mediumUrl;
  }

  return props.model.media.angledView?.largeUrl;
});

const fleetchartImageFront = computed(() => {
  if (props.model.media.frontViewColored) {
    if (mobile.value) {
      return props.model.media.frontViewColored.mediumUrl;
    }

    return props.model.media.frontViewColored.largeUrl;
  }

  if (mobile.value && props.model.media.frontView) {
    return props.model.media.frontView.mediumUrl;
  }

  return props.model.media.frontView?.largeUrl;
});

const fleetchartImageTop = computed(() => {
  if (props.model.media.topViewColored) {
    if (mobile.value) {
      return props.model.media.topViewColored.mediumUrl;
    }

    return props.model.media.topViewColored.largeUrl;
  }

  if (mobile.value && props.model.media.topView) {
    return props.model.media.topView.mediumUrl;
  }

  return props.model.media.topView?.largeUrl;
});

const fleetchartImageSide = computed(() => {
  if (props.model.media.sideViewColored) {
    if (mobile.value) {
      return props.model.media.sideViewColored.mediumUrl;
    }

    return props.model.media.sideViewColored.largeUrl;
  }

  if (mobile.value && props.model.media.sideView?.mediumUrl) {
    return props.model.media.sideView.mediumUrl;
  }

  return props.model.media.sideView?.largeUrl;
});

const windowWidth = ref(window.innerWidth / 2);

const maxFleetchartWidth = computed(
  () => windowWidth.value - (windowWidth.value / 100) * 40,
);

const length = computed(() => {
  if (!props.model) {
    return 0;
  }

  if (modelBeam.value > modelLength.value) {
    return (maxFleetchartWidth.value * modelLength.value) / modelBeam.value;
  }

  return maxFleetchartWidth.value;
});

const beam = computed(() => {
  if (!props.model) {
    return 0;
  }

  if (modelLength.value > modelBeam.value) {
    return (maxFleetchartWidth.value * modelBeam.value) / modelLength.value;
  }

  return maxFleetchartWidth.value;
});

const modelLength = computed(() => {
  if (!props.model || !props.model.metrics.fleetchartLength) {
    return 1;
  }

  return props.model.metrics.fleetchartLength;
});

const modelBeam = computed(() => {
  if (!props.model || !props.model.metrics.beam) {
    return 1;
  }

  return props.model.metrics.beam;
});

onMounted(() => {
  window.addEventListener("resize", () => {
    windowWidth.value = window.innerWidth / 2;
  });
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
