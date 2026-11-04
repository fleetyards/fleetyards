<script lang="ts">
export default {
  name: "FleetchartCanvasItem",
};
</script>

<script lang="ts" setup>
import { isCatalogueEntry } from "@/frontend/components/Fleetchart/catalogueShips";
import { useI18n } from "@/shared/composables/useI18n";
import {
  PIXELS_PER_METRE,
  imageUrlFor,
  modelOf,
  shipLabelOf,
  viewFor,
  type FleetchartEntry,
  type FleetchartShipGeometry,
} from "@/frontend/components/Fleetchart/geometry";
import {
  FleetchartFacings,
  FleetchartShipStates,
  FleetchartViewpoints,
} from "@/shared/stores/fleetchart";

interface Props {
  entry: FleetchartEntry;
  geometry: FleetchartShipGeometry;
  left: number;
  top: number;
  viewpoint: FleetchartViewpoints;
  zoom?: number;
  showLabel?: boolean;
  showStatus?: boolean;
  colored?: boolean;
  state?: FleetchartShipStates;
  tight?: boolean;
  boxWidth: number;
  boxHeight: number;
  facing?: FleetchartFacings;
  selected?: boolean;
  arranging?: boolean;
  order?: number;
}

const props = withDefaults(defineProps<Props>(), {
  zoom: 1,
  showLabel: false,
  showStatus: false,
  colored: false,
  state: FleetchartShipStates.FLIGHT,
  tight: false,
  facing: FleetchartFacings.LEFT,
  selected: false,
  arranging: false,
  order: undefined,
});

const { t } = useI18n();

const model = computed(() => modelOf(props.entry));

const label = computed(() => shipLabelOf(props.entry));

const notOwned = computed(() => isCatalogueEntry(props.entry));

const productionStatus = computed(() =>
  t(`labels.model.productionStatus.${model.value.productionStatus}`),
);

const cssClasses = computed(() => [
  `fleetchart-item-${model.value.slug}`,
  props.showStatus ? `status-${model.value.productionStatus}` : undefined,
  props.selected ? "fleetchart-canvas-item--selected" : undefined,
  props.arranging ? "fleetchart-canvas-item--arranging" : undefined,
  notOwned.value ? "fleetchart-canvas-item--not-owned" : undefined,
]);

const view = computed(() =>
  viewFor(props.entry, props.viewpoint, {
    state: props.state,
    colored: props.colored,
  }),
);

const imageWidth = computed(() => props.geometry.imageWidth * PIXELS_PER_METRE);

const image = computed(() => {
  if (!view.value) {
    return undefined;
  }

  const renderedWidth =
    (props.geometry.imageWidth || props.geometry.length) *
    PIXELS_PER_METRE *
    props.zoom *
    (window.devicePixelRatio || 1);

  return imageUrlFor(view.value, renderedWidth);
});
</script>

<template>
  <div
    class="fleetchart-canvas-item"
    :class="cssClasses"
    :style="{
      zIndex: order,
      left: `${left}px`,
      top: `${top}px`,
      width: `${boxWidth * PIXELS_PER_METRE}px`,
      height: `${boxHeight * PIXELS_PER_METRE}px`,
    }"
    data-test="fleetchart-ship"
  >
    <span
      v-if="notOwned"
      class="fleetchart-canvas-item__not-owned"
      data-test="fleetchart-ship-not-owned"
    >
      {{ t("labels.fleetchartApp.notOwned") }}
    </span>
    <div v-if="showLabel" class="fleetchart-canvas-item__label">
      <span>{{ label.title }}</span>
      <small v-if="label.subtitle">{{ label.subtitle }}</small>
      <small v-if="showStatus">{{ productionStatus }}</small>
    </div>
    <div
      class="fleetchart-canvas-item__frame"
      :class="[
        `fleetchart-canvas-item__frame--${facing}`,
        { 'fleetchart-canvas-item__frame--tight': tight },
      ]"
      :style="{
        width: `${geometry.frameWidth * PIXELS_PER_METRE}px`,
        height: `${geometry.height * PIXELS_PER_METRE}px`,
      }"
    >
      <img
        v-if="image"
        :src="image"
        :alt="label.title"
        draggable="false"
        :style="{
          width: `${imageWidth}px`,
          'max-height': `${geometry.height * PIXELS_PER_METRE}px`,
        }"
        class="fleetchart-canvas-item__image"
      />
    </div>
  </div>
</template>

<style lang="scss" scoped>
@import "index.scss";
</style>
