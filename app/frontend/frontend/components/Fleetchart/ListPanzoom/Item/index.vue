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
        :label="name || modelName"
        :src="image"
        :width="imageWidth"
        :height="height"
      />
    </div>
  </div>
</template>

<script lang="ts" setup>
import { useI18n } from "@/frontend/composables/useI18n";
import FleetchartItemImage from "./Image/index.vue";

type ViewType = "top" | "side" | "angled" | "front";

type Props = {
  item: Model | Vehicle;
  viewpoint?: ViewType;
  showLabel?: boolean;
  showStatus?: boolean;
  sizeMultiplicator?: number;
  scale?: number;
  colored?: boolean;
};

const props = withDefaults(defineProps<Props>(), {
  viewpoint: "side",
  showLabel: false,
  showStatus: false,
  sizeMultiplicator: 1,
  scale: 1,
  colored: false,
});

const { t } = useI18n();

const imageByViewpoint = computed<FyMediaViewImage>(() => {
  if (props.viewpoint === "angled") {
    return angledView.value as FyMediaViewImage;
  }

  if (props.viewpoint === "front") {
    return frontView.value as FyMediaViewImage;
  }

  if (props.viewpoint === "side") {
    return sideView.value as FyMediaViewImage;
  }

  return topView.value as FyMediaViewImage;
});

const model = computed<Model>(() => {
  if (props.item && (props.item as Vehicle).model) {
    return (props.item as Vehicle).model as Model;
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
    if (props.colored && modulePackage.value.media.angledViewColored) {
      return modulePackage.value.media.angledViewColored;
    }

    return modulePackage.value.media.angledView;
  }

  if (props.colored && model.value.media.angledViewColored) {
    return model.value.media.angledViewColored;
  }

  return model.value.media.angledView;
});

const frontView = computed(() => {
  if (props.colored && paint.value && paint.value.media.frontView) {
    return paint.value.media.frontView;
  }

  if (modulePackage.value && modulePackage.value.media.frontView) {
    if (props.colored && modulePackage.value.media.frontViewColored) {
      return modulePackage.value.media.frontViewColored;
    }

    return modulePackage.value.media.frontView;
  }

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
    if (props.colored && modulePackage.value.media.sideViewColored) {
      return modulePackage.value.media.sideViewColored;
    }

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
    if (props.colored && modulePackage.value.media.topViewColored) {
      return modulePackage.value.media.topViewColored;
    }

    return modulePackage.value.media.topView;
  }

  if (props.colored && model.value.media.topViewColored?.source) {
    return model.value.media.topViewColored;
  }

  return model.value.media.topView;
});

const cssClasses = computed(() => {
  const cssClasses = [`fleetchart-item-${model.value.slug}`];

  if (props.showStatus) {
    cssClasses.push(`status-${model.value.productionStatus}`);
  }

  if (props.showLabel) {
    cssClasses.push("fleetchart-item-with-labels");
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
    return `${model.value.manufacturer.code} ${paint.value.name}`;
  }

  return `${model.value.manufacturer.code} ${model.value.name}`;
});

const length = computed(
  () => model.value.fleetchartLength * props.sizeMultiplicator,
);

const height = computed(
  () => (length.value * sourceImageHeightMax.value) / sourceImageWidthMax.value,
);

const imageWidth = computed(() =>
  Math.min(
    (height.value * sourceImageWidth.value) / sourceImageHeight.value,
    length.value,
  ),
);

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
    return imageByViewpoint.value?.source;
  }

  if (width > 900) {
    return imageByViewpoint.value?.large;
  }

  return imageByViewpoint.value?.medium;
});
</script>

<script lang="ts">
export default {
  name: "FleetchartListItem",
};
</script>
