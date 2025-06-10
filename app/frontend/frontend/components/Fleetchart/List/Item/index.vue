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
import FleetchartItemImage from "./Image/index.vue";
import { FleetchartViewpoints } from "@/shared/stores/fleetchart";
import {
  Model,
  Vehicle,
  VehiclePublic,
  ModelPaint,
  ModelModulePackage,
} from "@/services/fyApi";
import { useI18n } from "@/shared/composables/useI18n";

type Props = {
  item: Vehicle | Model | VehiclePublic;
  viewpoint: FleetchartViewpoints;
  showLabel: boolean;
  showStatus: boolean;
  sizeMultiplicator: number;
  scale: number;
};

const props = withDefaults(defineProps<Props>(), {
  showLabel: false,
  showStatus: false,
  sizeMultiplicator: 1,
  scale: 1,
});

const { t } = useI18n();

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

const model = computed(() => {
  if (props.item && (props.item as Vehicle).model) {
    return (props.item as Vehicle).model;
  }

  return props.item as Model;
});

const vehicle = computed(() => {
  if (props.item && (props.item as Vehicle).model) {
    return props.item as Vehicle;
  }

  return undefined;
});

const paint = computed(() => {
  if (vehicle.value && vehicle.value.paint) {
    return vehicle.value.paint;
  }

  return null;
});

const modulePackage = computed(() => {
  if (vehicle.value && vehicle.value.modulePackage) {
    return vehicle.value.modulePackage;
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
    (paint.value.media.topView ||
      paint.value.media.sideView ||
      paint.value.media.angledView)
  ) {
    const url = extractImageFromModel(paint.value);
    if (url) {
      return url;
    }
  }

  return extractImageFromModel(model.value);
});

const viewpointTop = computed(() => {
  return props.viewpoint === "top";
});

const viewpointSide = computed(() => {
  return props.viewpoint === "side";
});

const viewpointAngled = computed(() => {
  return props.viewpoint === "angled";
});

const productionStatus = computed(() => {
  return t(`labels.model.productionStatus.${model.value.productionStatus}`);
});

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

const length = computed(() => {
  return (
    (model.value.metrics.fleetchartLength || 0) *
    props.sizeMultiplicator *
    props.scale
  );
});

const height = computed(() => {
  return (
    (length.value * sourceImageHeightMax.value) / sourceImageWidthMax.value
  );
});

const imageWidth = computed(() => {
  if (!sourceImageWidth.value || !sourceImageHeight.value) {
    return length.value;
  }

  return Math.min(
    (height.value * sourceImageWidth.value) / sourceImageHeight.value,
    length.value,
  );
});

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
    (modulePackage.value.media.topView ||
      modulePackage.value.media.sideView ||
      modulePackage.value.media.angledView)
  ) {
    const height = extractImageWidthFromModel(modulePackage.value);
    if (height) {
      return height;
    }
  }

  if (
    paint.value &&
    (paint.value.media.topView ||
      paint.value.media.sideView ||
      paint.value.media.angledView)
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
    (modulePackage.value.media.topView ||
      modulePackage.value.media.sideView ||
      modulePackage.value.media.angledView)
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
  model: Model | ModelPaint | ModelModulePackage,
) => {
  if (viewpointTop.value && model.media.topView) {
    return topView(model);
  }

  if (viewpointSide.value && model.media.sideView) {
    return sideView(model);
  }

  if (viewpointAngled.value && model.media.angledView) {
    return angledView(model);
  }

  return null;
};

const extractMaxWidthFromModel = (
  model: Model | ModelPaint | ModelModulePackage,
) => {
  return Math.max(
    model.media.topView?.width || 0,
    model.media.sideView?.width || 0,
    model.media.angledView?.width || 0,
  );
};

const extractMaxHeightFromModel = (
  model: Model | ModelPaint | ModelModulePackage,
) => {
  return Math.max(
    model.media.topView?.height || 0,
    model.media.sideView?.height || 0,
    model.media.angledView?.height || 0,
  );
};

const extractImageHeightFromModel = (
  model: Model | ModelPaint | ModelModulePackage,
) => {
  if (viewpointTop.value && model.media.topView) {
    return model.media.topView.height;
  }

  if (viewpointSide.value && model.media.sideView) {
    return model.media.sideView.height;
  }

  if (viewpointAngled.value && model.media.angledView) {
    return model.media.angledView.height;
  }

  return null;
};

const extractImageWidthFromModel = (
  model: Model | ModelPaint | ModelModulePackage,
) => {
  if (viewpointTop.value && model.media.topView) {
    return model.media.topView.width;
  }

  if (viewpointSide.value && model.media.sideView) {
    return model.media.sideView.width;
  }

  if (viewpointAngled.value && model.media.angledView) {
    return model.media.angledView.width;
  }

  return null;
};

const topView = (model: Model | ModelPaint | ModelModulePackage) => {
  const width = length.value * props.sizeMultiplicator * props.scale;

  if (width > 1900) {
    return model.topView;
  }

  return model.topViewLarge;
};

const sideView = (model: Model | ModelPaint | ModelModulePackage) => {
  const width = length.value * props.sizeMultiplicator * props.scale;

  if (width > 1900) {
    return model.sideView;
  }

  return model.sideViewLarge;
};

const angledView = (model: Model | ModelPaint | ModelModulePackage) => {
  const width = length.value * props.sizeMultiplicator * props.scale;

  if (width > 1900) {
    return model.angledView;
  }

  return model.angledViewLarge;
};
</script>

<script lang="ts">
export default {
  name: "FleetchartListItem",
};
</script>
