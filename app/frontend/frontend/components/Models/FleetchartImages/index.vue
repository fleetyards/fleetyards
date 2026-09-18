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
import Loader from "@/shared/components/Loader/index.vue";
import {
  ModelStateEnum,
  ModelViewEnum,
  modelStateMetrics,
  modelStateView,
  useModelStates,
} from "@/frontend/composables/useModelStates";

import type { Model, MediaFile } from "@/services/fyApi";

type Props = {
  model: Model;
  state?: ModelStateEnum;
};

const props = withDefaults(defineProps<Props>(), {
  state: ModelStateEnum.FLIGHT,
});

const emit = defineEmits<{
  (e: "update:state", value: ModelStateEnum): void;
}>();

const { t } = useI18n();

const mobile = useMobile();

const { availableStates } = useModelStates(() => props.model);

const setState = (value: ModelStateEnum) => {
  emit("update:state", value);
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

const viewUrl = (view: ModelViewEnum) => {
  const { colored, regular } = modelStateView(props.model, props.state, view);

  return pickViewUrl(colored, regular);
};

const fleetchartImageAngled = computed(() => viewUrl(ModelViewEnum.ANGLED));

const fleetchartImageFront = computed(() => viewUrl(ModelViewEnum.FRONT));

const fleetchartImageTop = computed(() => viewUrl(ModelViewEnum.TOP));

const fleetchartImageSide = computed(() => viewUrl(ModelViewEnum.SIDE));

// The coloured views run to several megabytes each, so switching state leaves the
// previous set on screen for a beat. Settled by URL rather than by a counter: the
// four <img> elements stay put across a switch, so each one reports the file it
// just finished, and an image already in the browser cache reports immediately.
const settledUrls = ref(new Set<string>());

const currentUrls = computed(() =>
  [
    fleetchartImageAngled.value,
    fleetchartImageTop.value,
    fleetchartImageFront.value,
    fleetchartImageSide.value,
  ].filter((url): url is string => Boolean(url)),
);

const loading = computed(() =>
  currentUrls.value.some((url) => !settledUrls.value.has(url)),
);

// An image that fails settles too, or the loader would sit over a view that is
// never going to arrive.
const settleImage = (event: Event) => {
  const image = event.target as HTMLImageElement;

  // A `load` belonging to the file the switch navigated away from: the element
  // has already been pointed at its replacement, so the src attribute reads as
  // the new file and settling on it would clear the loader over an image still
  // arriving. The element's own `complete` is what knows the difference.
  if (event.type === "load" && !image.complete) {
    return;
  }

  const url = image.getAttribute("src");

  if (!url) {
    return;
  }

  settledUrls.value = new Set(settledUrls.value).add(url);
};

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

const stateMetrics = computed(() =>
  modelStateMetrics(props.model, props.state),
);

const modelLength = computed(() => stateMetrics.value.fleetchartLength || 1);

const modelBeam = computed(() => stateMetrics.value.fleetchartBeam || 1);

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
    <BtnGroup
      v-if="availableStates.length > 1"
      segmented
      class="fleetchart-views-toggle"
      data-test="model-states"
    >
      <Btn
        v-for="modelState in availableStates"
        :key="modelState"
        :active="state === modelState"
        :data-test="`model-state-${modelState}`"
        @click="setState(modelState)"
      >
        {{ t(`labels.model.state.${modelState}`) }}
      </Btn>
    </BtnGroup>
    <div
      class="fleetchart-views"
      :class="{ 'fleetchart-views--loading': loading }"
    >
      <!-- Announced here rather than inside Loader: it is a leaf component
           mounted without a store in several specs, and useI18n needs pinia. -->
      <Loader
        relative
        :loading="loading"
        role="status"
        :aria-label="t('labels.loading')"
      />
      <div>
        <img
          v-if="fleetchartImageAngled"
          :src="fleetchartImageAngled"
          :width="(length > beam ? length : beam) * 1.2"
          @load="settleImage"
          @error="settleImage"
        />
      </div>
      <div>
        <img
          v-if="fleetchartImageTop"
          :src="fleetchartImageTop"
          :width="length"
          @load="settleImage"
          @error="settleImage"
        />
      </div>
      <div :class="{ small: mobile }">
        <img
          v-if="fleetchartImageFront"
          :src="fleetchartImageFront"
          :style="sideViewHeight ? { maxHeight: sideViewHeight + 'px' } : {}"
          @load="settleImage"
          @error="settleImage"
        />
      </div>
      <div>
        <img
          v-if="fleetchartImageSide"
          ref="sideViewImg"
          :src="fleetchartImageSide"
          :width="length"
          @load="
            updateSideViewHeight();
            settleImage($event);
          "
          @error="settleImage"
        />
      </div>
    </div>
  </div>
</template>

<style scoped lang="scss">
@import "index.scss";
</style>
