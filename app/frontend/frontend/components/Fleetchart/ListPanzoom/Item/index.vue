<template>
  <div
    class="fleetchart-item fade-list-item"
    :style="{
      'min-height': `${height}px`,
    }"
    :class="cssClasses"
  >
    <div v-if="showLabel" class="fleetchart-item-label">
      <template v-if="name">
        <span>{{ name }}</span>
        <small>
          <span>{{ modelName }}</span>
          <template v-if="showStatus"><br />{{ productionStatus }}</template>
        </small>
      </template>
      <template v-else>
        <span>{{ modelName }}</span>
        <small v-if="showStatus">
          {{ productionStatus }}
        </small>
      </template>
    </div>
    <div
      class="fleetchart-item-image-wrapper"
      :style="{
        width: `${length}px`,
        height: `${height}px`,
      }"
    >
      <FleetchartItemImage
        v-if="image"
        :label="name || modelName"
        :src="image"
        :width="imageWidth"
        :height="height"
      />
    </div>
  </div>
</template>

<script lang="ts" setup>
import { useI18n } from "@/shared/composables/useI18n";
import FleetchartItemImage from "./Image/index.vue";
import type {
  Model,
  Vehicle,
  VehiclePublic,
  ModelModulePackage,
  MediaFile,
  ModelPaint,
} from "@/services/fyApi";
import { FleetchartViewpoints } from "@/shared/stores/fleetchart";

type Props = {
  item: Vehicle | Model | VehiclePublic;
  viewpoint?: FleetchartViewpoints;
  showLabel?: boolean;
  showStatus?: boolean;
  sizeMultiplicator?: number;
  scale?: number;
  colored?: boolean;
};

const props = withDefaults(defineProps<Props>(), {
  viewpoint: FleetchartViewpoints.SIDE,
  showLabel: false,
  showStatus: false,
  sizeMultiplicator: 1,
  scale: 1,
  colored: false,
});

const { t } = useI18n();

const imageByViewpoint = computed<MediaFile | undefined>(() => {
  if (props.viewpoint === "angled") {
    return angledView.value;
  }

  if (props.viewpoint === "front") {
    return frontView.value;
  }

  if (props.viewpoint === "side") {
    return sideView.value;
  }

  return topView.value;
});

const model = computed<Model>(() => {
  if (props.item && (props.item as Vehicle).model) {
    return (props.item as Vehicle).model;
  }

  return props.item as Model;
});

const vehicle = computed<Vehicle | null>(() => {
  if (props.item && (props.item as Vehicle).model) {
    return props.item as Vehicle;
  }

  return null;
});

const modulePackage = computed<ModelModulePackage | null>(() => {
  if (vehicle.value && vehicle.value.modulePackage) {
    return vehicle.value.modulePackage;
  }

  return null;
});

const paint = computed<ModelPaint | null>(() => {
  if (vehicle.value && vehicle.value.paint) {
    return vehicle.value.paint;
  }

  return null;
});

const angledView = computed(() => {
  if (props.colored && paint.value && paint.value.media.angledView) {
    return paint.value.media.angledView;
  }

  if (modulePackage.value && modulePackage.value.media.angledView) {
    // if (props.colored && modulePackage.value.media.angledViewColored) {
    //   return modulePackage.value.media.angledViewColored;
    // }

    return modulePackage.value.media.angledView;
  }

  if (props.colored && model.value.media.angledViewColored) {
    return model.value.media.angledViewColored;
  }

  return model.value.media.angledView;
});

const frontView = computed(() => {
  // if (props.colored && paint.value && paint.value.media.frontView) {
  //   return paint.value.media.frontView;
  // }

  // if (modulePackage.value && modulePackage.value.media.frontView) {
  //   if (props.colored && modulePackage.value.media.frontViewColored) {
  //     return modulePackage.value.media.frontViewColored;
  //   }

  //   return modulePackage.value.media.frontView;
  // }

  if (props.colored && model.value.media.frontViewColored) {
    return model.value.media.frontViewColored;
  }

  return model.value.media.frontView;
});

const sideView = computed(() => {
  if (props.colored && paint.value && paint.value.media.sideView) {
    return paint.value.media.sideView;
  }

  if (modulePackage.value && modulePackage.value.media.sideView) {
    // if (props.colored && modulePackage.value.media.sideViewColored) {
    //   return modulePackage.value.media.sideViewColored;
    // }

    return modulePackage.value.media.sideView;
  }

  if (props.colored && model.value.media.sideViewColored) {
    return model.value.media.sideViewColored;
  }

  return model.value.media.sideView;
});

const topView = computed(() => {
  if (props.colored && paint.value && paint.value.media.topView) {
    return paint.value.media.topView;
  }

  if (modulePackage.value && modulePackage.value.media.topView) {
    // if (props.colored && modulePackage.value.media.topViewColored) {
    //   return modulePackage.value.media.topViewColored;
    // }

    return modulePackage.value.media.topView;
  }

  if (props.colored && model.value.media.topViewColored?.url) {
    return model.value.media.topViewColored;
  }

  return model.value.media.topView;
});

const cssClasses = computed(() => {
  const cssClasses = [`fleetchart-item-${model.value.slug}`];

  if (props.showStatus) {
    cssClasses.push(`status-${model.value.productionStatus}`);
  }

  return cssClasses;
});

const productionStatus = computed(() =>
  t(`labels.model.productionStatus.${model.value.productionStatus}`),
);

const name = computed(() => {
  if (vehicle.value && vehicle.value.name) {
    return vehicle.value.name;
  }

  return null;
});

const modelName = computed(() => {
  if (paint.value && paint.value.rsiId) {
    return `${model.value.manufacturer?.code} ${paint.value.name}`;
  }

  return `${model.value.manufacturer?.code} ${model.value.name}`;
});

const length = computed(
  () => (model.value.metrics.fleetchartLength || 0) * props.sizeMultiplicator,
);

const height = computed(
  () => (length.value * sourceImageHeightMax.value) / sourceImageWidthMax.value,
);

const imageWidth = computed(() => {
  if (!sourceImageWidth.value || !sourceImageHeight.value) {
    return 0;
  }

  return Math.min(
    (height.value * sourceImageWidth.value) / sourceImageHeight.value,
    length.value,
  );
});

const sourceImageHeight = computed(() => imageByViewpoint.value?.height);

const sourceImageHeightMax = computed(() =>
  Math.max(
    ...([
      angledView.value?.height,
      sideView.value?.height,
      topView.value?.height,
    ].filter(Boolean) as number[]),
  ),
);

const sourceImageWidth = computed(() => imageByViewpoint.value?.width);

const sourceImageWidthMax = computed(() =>
  Math.max(
    ...([
      angledView.value?.width,
      sideView.value?.width,
      topView.value?.width,
    ].filter(Boolean) as number[]),
  ),
);

const image = computed(() => {
  const width = length.value * props.sizeMultiplicator * props.scale;

  if (width > 1900) {
    return imageByViewpoint.value?.url;
  }

  if (width > 900) {
    return imageByViewpoint.value?.largeUrl;
  }

  return imageByViewpoint.value?.mediumUrl;
});
</script>

<script lang="ts">
export default {
  name: "FleetchartListItem",
};
</script>

<style lang="scss" scoped>
@import "index.scss";
</style>
