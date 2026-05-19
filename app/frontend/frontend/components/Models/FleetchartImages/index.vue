<script lang="ts">
export default {
  name: "ModelsFleetchartImages",
};
</script>

<script lang="ts" setup>
import { useMobile } from "@/shared/composables/useMobile";
import { useI18n } from "@/shared/composables/useI18n";
import Btn from "@/shared/components/base/Btn/index.vue";
import BtnGroup from "@/shared/components/base/BtnGroup/index.vue";
import { BtnSizesEnum } from "@/shared/components/base/Btn/types";
import type { Model, MediaFile } from "@/services/fyApi";

type Props = {
  model: Model;
  extended?: boolean;
};

const props = withDefaults(defineProps<Props>(), {
  extended: false,
});

const emit = defineEmits<{
  (e: "update:extended", value: boolean): void;
}>();

const { t } = useI18n();

const mobile = useMobile();

const hasExtendedState = computed(() => {
  return Boolean(
    props.model.metrics.extendedLength ||
    props.model.media.extendedHolo ||
    props.model.media.extendedTopView ||
    props.model.media.extendedSideView ||
    props.model.media.extendedAngledView ||
    props.model.media.extendedFrontView,
  );
});

const setExtended = (value: boolean) => {
  emit("update:extended", value);
};

const hasImages = computed(() => {
  return (
    fleetchartImageAngled.value ||
    fleetchartImageFront.value ||
    fleetchartImageTop.value ||
    fleetchartImageSide.value
  );
});

const pickViewUrl = (
  colored: MediaFile | undefined,
  regular: MediaFile | undefined,
) => {
  if (colored) {
    return mobile.value ? colored.mediumUrl : colored.largeUrl;
  }

  if (mobile.value && regular?.mediumUrl) {
    return regular.mediumUrl;
  }

  return regular?.largeUrl;
};

const fleetchartImageAngled = computed(() => {
  if (props.extended) {
    const url = pickViewUrl(
      props.model.media.extendedAngledViewColored,
      props.model.media.extendedAngledView,
    );
    if (url) return url;
  }

  return pickViewUrl(
    props.model.media.angledViewColored,
    props.model.media.angledView,
  );
});

const fleetchartImageFront = computed(() => {
  if (props.extended) {
    const url = pickViewUrl(
      props.model.media.extendedFrontViewColored,
      props.model.media.extendedFrontView,
    );
    if (url) return url;
  }

  return pickViewUrl(
    props.model.media.frontViewColored,
    props.model.media.frontView,
  );
});

const fleetchartImageTop = computed(() => {
  if (props.extended) {
    const url = pickViewUrl(
      props.model.media.extendedTopViewColored,
      props.model.media.extendedTopView,
    );
    if (url) return url;
  }

  return pickViewUrl(
    props.model.media.topViewColored,
    props.model.media.topView,
  );
});

const fleetchartImageSide = computed(() => {
  if (props.extended) {
    const url = pickViewUrl(
      props.model.media.extendedSideViewColored,
      props.model.media.extendedSideView,
    );
    if (url) return url;
  }

  return pickViewUrl(
    props.model.media.sideViewColored,
    props.model.media.sideView,
  );
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
  if (!props.model) {
    return 1;
  }

  if (props.extended) {
    const extended =
      props.model.metrics.extendedFleetchartOffsetLength ||
      props.model.metrics.extendedLength;
    if (extended) return extended;
  }

  return props.model.metrics.fleetchartOffsetLength || 1;
});

const modelBeam = computed(() => {
  if (!props.model) {
    return 1;
  }

  if (props.extended) {
    const extended =
      props.model.metrics.extendedFleetchartOffsetBeam ||
      props.model.metrics.extendedBeam;
    if (extended) return extended;
  }

  return props.model.metrics.fleetchartOffsetBeam || 1;
});

const sideViewImg = ref<HTMLImageElement | null>(null);
const sideViewHeight = ref(0);

const updateSideViewHeight = () => {
  if (sideViewImg.value) {
    sideViewHeight.value = sideViewImg.value.clientHeight;
  }
};

onMounted(() => {
  window.addEventListener("resize", () => {
    windowWidth.value = window.innerWidth / 2;
    updateSideViewHeight();
  });
});
</script>

<template>
  <div v-if="hasImages" class="fleetchart-views-wrapper">
    <BtnGroup v-if="hasExtendedState" class="fleetchart-views-toggle">
      <Btn
        :active="!extended"
        :size="BtnSizesEnum.SMALL"
        @click="setExtended(false)"
      >
        {{ t("labels.model.state.retracted") }}
      </Btn>
      <Btn
        :active="extended"
        :size="BtnSizesEnum.SMALL"
        @click="setExtended(true)"
      >
        {{ t("labels.model.state.extended") }}
      </Btn>
    </BtnGroup>
    <div class="fleetchart-views">
      <div>
        <img
          v-if="fleetchartImageAngled"
          :src="fleetchartImageAngled"
          :width="(length > beam ? length : beam) * 1.2"
        />
      </div>
      <div>
        <img
          v-if="fleetchartImageTop"
          :src="fleetchartImageTop"
          :width="length"
        />
      </div>
      <div :class="{ small: mobile }">
        <img
          v-if="fleetchartImageFront"
          :src="fleetchartImageFront"
          :style="sideViewHeight ? { maxHeight: sideViewHeight + 'px' } : {}"
        />
      </div>
      <div>
        <img
          v-if="fleetchartImageSide"
          ref="sideViewImg"
          :src="fleetchartImageSide"
          :width="length"
          @load="updateSideViewHeight"
        />
      </div>
    </div>
  </div>
</template>

<style scoped lang="scss">
@import "index.scss";
</style>
