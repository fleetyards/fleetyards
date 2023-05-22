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

type ModelViewType =
  | "topView"
  | "topViewColored"
  | "sideView"
  | "sideViewColored"
  | "angledView"
  | "angledViewColored"
  | "frontView"
  | "frontViewColored";

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

const view = computed<ModelViewType>(() => {
  if (props.colored && model.value[`${props.viewpoint}ViewColored`]) {
    return `${props.viewpoint}ViewColored`;
  }

  return `${props.viewpoint}View`;
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

const paint = computed<ModelPaint | null>(() => {
  if (vehicle.value && vehicle.value.paint) {
    return props.item as ModelPaint;
  }

  return null;
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

const modulePackage = computed<ModelModulePackage | null>(() => {
  if (vehicle.value && vehicle.value.modulePackage) {
    return vehicle.value.modulePackage as ModelModulePackage;
  }

  return null;
});

const image = computed(() => {
  if (
    modulePackage.value &&
    (modulePackage.value.topView ||
      modulePackage.value.sideView ||
      modulePackage.value.angledView)
  ) {
    const url = extractImageFromModel(modulePackage.value);
    if (url) {
      return url;
    }
  }

  if (
    paint.value &&
    (paint.value.topView || paint.value.sideView || paint.value.angledView)
  ) {
    const url = extractImageFromModel(paint.value);
    if (url) {
      return url;
    }
  }

  return extractImageFromModel(model.value);
});

const productionStatus = computed(() =>
  t(`labels.model.productionStatus.${model.value.productionStatus}`)
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
  () => model.value.fleetchartLength * props.sizeMultiplicator
);

const height = computed(
  () => (length.value * sourceImageHeightMax.value) / sourceImageWidthMax.value
);

const imageWidth = computed(() =>
  Math.min(
    (height.value * sourceImageWidth.value) / sourceImageHeight.value,
    length.value
  )
);

const sourceImageHeightMax = computed(() => {
  if (
    modulePackage.value &&
    (modulePackage.value.topView ||
      modulePackage.value.sideView ||
      modulePackage.value.angledView)
  ) {
    const height = extractMaxHeightFromModel(modulePackage.value);
    if (height) {
      return height;
    }
  }

  if (
    paint.value &&
    (paint.value.topView || paint.value.sideView || paint.value.angledView)
  ) {
    const height = extractMaxHeightFromModel(paint.value);
    if (height) {
      return height;
    }
  }

  return extractMaxHeightFromModel(model.value);
});

const sourceImageHeight = computed(() => {
  if (
    modulePackage.value &&
    (modulePackage.value.topView ||
      modulePackage.value.sideView ||
      modulePackage.value.angledView)
  ) {
    const height = extractImageHeightFromModel(modulePackage.value);
    if (height) {
      return height;
    }
  }

  if (
    paint.value &&
    (paint.value.topView || paint.value.sideView || paint.value.angledView)
  ) {
    const height = extractImageHeightFromModel(paint.value);
    if (height) {
      return height;
    }
  }

  return extractImageHeightFromModel(model.value);
});

const sourceImageWidth = computed(() => {
  if (
    modulePackage.value &&
    (modulePackage.value.topView ||
      modulePackage.value.sideView ||
      modulePackage.value.angledView)
  ) {
    const height = extractImageWidthFromModel(modulePackage.value);
    if (height) {
      return height;
    }
  }

  if (
    paint.value &&
    (paint.value.topView || paint.value.sideView || paint.value.angledView)
  ) {
    const width = extractImageWidthFromModel(paint.value);
    if (width) {
      return width;
    }
  }

  return extractImageWidthFromModel(model.value);
});

const sourceImageWidthMax = computed(() => {
  if (
    modulePackage.value &&
    (modulePackage.value.topView ||
      modulePackage.value.sideView ||
      modulePackage.value.angledView)
  ) {
    const width = extractMaxWidthFromModel(modulePackage.value);
    if (width) {
      return width;
    }
  }

  if (
    paint.value &&
    (paint.value.topView || paint.value.sideView || paint.value.angledView)
  ) {
    const width = extractMaxWidthFromModel(paint.value);
    if (width) {
      return width;
    }
  }

  return extractMaxWidthFromModel(model.value);
});

const extractImageFromModel = (
  model: Model | ModelModulePackage | ModelPaint
) => {
  const width = length.value * props.sizeMultiplicator * props.scale;

  if (width > 1900) {
    return model[view.value];
  }

  if (width > 900) {
    return model[`${view.value}Large`];
  }

  return model[`${view.value}Medium`];
};

const extractMaxWidthFromModel = (
  model: Model | ModelModulePackage | ModelPaint
) => Math.max(model.topViewWidth, model.sideViewWidth, model.angledViewWidth);

const extractMaxHeightFromModel = (
  model: Model | ModelModulePackage | ModelPaint
) =>
  Math.max(model.topViewHeight, model.sideViewHeight, model.angledViewHeight);

const extractImageHeightFromModel = (
  model: Model | ModelModulePackage | ModelPaint
) => model[`${view.value}Height`];

const extractImageWidthFromModel = (
  model: Model | ModelModulePackage | ModelPaint
) => model[`${view.value}Width`];
</script>

<script lang="ts">
export default {
  name: "FleetchartListItem",
};
</script>
