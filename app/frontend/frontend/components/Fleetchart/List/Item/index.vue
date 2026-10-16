<script lang="ts">
export default {
  name: "FleetchartListItem",
};
</script>

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
  extended?: boolean;
};

const props = withDefaults(defineProps<Props>(), {
  showLabel: false,
  showStatus: false,
  sizeMultiplicator: 1,
  scale: 1,
  extended: false,
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

const effectiveModel = computed<Model>(() => {
  if (!props.extended) {
    return model.value;
  }

  const m = model.value;

  return {
    ...m,
    media: {
      ...m.media,
      topView: m.media.extendedTopView ?? m.media.topView,
      portView: m.media.extendedPortView ?? m.media.portView,
      angledView: m.media.extendedAngledView ?? m.media.angledView,
      frontView: m.media.extendedFrontView ?? m.media.frontView,
    },
    metrics: {
      ...m.metrics,
      fleetchartOffsetLength:
        m.metrics.extendedFleetchartOffsetLength ||
        m.metrics.extendedLength ||
        m.metrics.fleetchartOffsetLength,
      fleetchartOffsetBeam:
        m.metrics.extendedFleetchartOffsetBeam ||
        m.metrics.extendedBeam ||
        m.metrics.fleetchartOffsetBeam,
    },
  };
});

const vehicle = computed(() => {
  if (props.item && (props.item as Vehicle).model) {
    return props.item as Vehicle;
  }

  return undefined;
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
    (modulePackage.value.media.topView ||
      modulePackage.value.media.portView ||
      modulePackage.value.media.angledView)
  ) {
    const url = extractImageFromModel(modulePackage.value);
    if (url) {
      return url;
    }
  }

  return extractImageFromModel(effectiveModel.value);
});

const viewpointTop = computed(() => {
  return props.viewpoint === "top";
});

const viewpointPort = computed(() => {
  return props.viewpoint === "port";
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
  return `${model.value.manufacturer?.code} ${model.value.name}`;
});

const length = computed(() => {
  return (
    (effectiveModel.value.metrics.fleetchartOffsetLength || 0) *
    props.sizeMultiplicator *
    props.scale
  );
});

const beam = computed(() => {
  return (
    (effectiveModel.value.metrics.fleetchartOffsetBeam || 0) *
    props.sizeMultiplicator *
    props.scale
  );
});

const height = computed(() => {
  return (
    (Math.max(length.value, beam.value) * sourceImageHeightMax.value) /
    sourceImageWidthMax.value
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
    (modulePackage.value.media.topView ||
      modulePackage.value.media.portView ||
      modulePackage.value.media.angledView)
  ) {
    const height = extractMaxHeightFromModel(modulePackage.value);
    if (height) {
      return height;
    }
  }

  return extractMaxHeightFromModel(effectiveModel.value);
});

const sourceImageHeight = computed(() => {
  if (
    modulePackage.value &&
    (modulePackage.value.media.topView ||
      modulePackage.value.media.portView ||
      modulePackage.value.media.angledView)
  ) {
    const height = extractImageHeightFromModel(modulePackage.value);
    if (height) {
      return height;
    }
  }

  return extractImageHeightFromModel(effectiveModel.value);
});

const sourceImageWidth = computed(() => {
  if (
    modulePackage.value &&
    (modulePackage.value.media.topView ||
      modulePackage.value.media.portView ||
      modulePackage.value.media.angledView)
  ) {
    const height = extractImageWidthFromModel(modulePackage.value);
    if (height) {
      return height;
    }
  }

  return extractImageWidthFromModel(effectiveModel.value);
});

const sourceImageWidthMax = computed(() => {
  if (
    modulePackage.value &&
    (modulePackage.value.media.topView ||
      modulePackage.value.media.portView ||
      modulePackage.value.media.angledView)
  ) {
    const width = extractMaxWidthFromModel(modulePackage.value);
    if (width) {
      return width;
    }
  }

  return extractMaxWidthFromModel(effectiveModel.value);
});

const extractImageFromModel = (
  model: Model | ModelPaint | ModelModulePackage,
) => {
  if (viewpointTop.value && model.media.topView) {
    return topView(model);
  }

  if (viewpointPort.value && model.media.portView) {
    return portView(model);
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
    model.media.portView?.width || 0,
    model.media.angledView?.width || 0,
  );
};

const extractMaxHeightFromModel = (
  model: Model | ModelPaint | ModelModulePackage,
) => {
  return Math.max(
    model.media.topView?.height || 0,
    model.media.portView?.height || 0,
    model.media.angledView?.height || 0,
  );
};

const extractImageHeightFromModel = (
  model: Model | ModelPaint | ModelModulePackage,
) => {
  if (viewpointTop.value && model.media.topView) {
    return model.media.topView.height;
  }

  if (viewpointPort.value && model.media.portView) {
    return model.media.portView.height;
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

  if (viewpointPort.value && model.media.portView) {
    return model.media.portView.width;
  }

  if (viewpointAngled.value && model.media.angledView) {
    return model.media.angledView.width;
  }

  return null;
};

const topView = (model: Model | ModelPaint | ModelModulePackage) => {
  const width = length.value * props.sizeMultiplicator * props.scale;

  if (width > 1900) {
    return model.media.topView?.url;
  }

  return model.media.topView?.largeUrl;
};

const portView = (model: Model | ModelPaint | ModelModulePackage) => {
  const width = length.value * props.sizeMultiplicator * props.scale;

  if (width > 1900) {
    return model.media.portView?.url;
  }

  return model.media.portView?.largeUrl;
};

const angledView = (model: Model | ModelPaint | ModelModulePackage) => {
  const width = length.value * props.sizeMultiplicator * props.scale;

  if (width > 1900) {
    return model.media.angledView?.url;
  }

  return model.media.angledView?.largeUrl;
};
</script>

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
