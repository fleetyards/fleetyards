<script lang="ts">
export default {
  name: "FleetchartCanvasShipControls",
};
</script>

<script lang="ts" setup>
import Btn from "@/shared/components/base/Btn/index.vue";
import { useI18n } from "@/shared/composables/useI18n";
import { FleetchartViewpoints } from "@/shared/stores/fleetchart";

interface Props {
  viewpoint: FleetchartViewpoints;
  available: FleetchartViewpoints[];
}

defineProps<Props>();

const emit = defineEmits<{
  rotate: [];
  "update:viewpoint": [viewpoint: FleetchartViewpoints];
}>();

const { t } = useI18n();
</script>

<template>
  <div
    class="fleetchart-canvas-ship-controls"
    role="toolbar"
    :aria-label="t('labels.fleetchartApp.shipControls')"
    data-test="fleetchart-ship-controls"
  >
    <Btn
      v-for="option in FleetchartViewpoints"
      :key="option"
      :active="viewpoint === option"
      :disabled="!available.includes(option)"
      :data-test="`fleetchart-ship-view-${option}`"
      size="sm"
      @click="emit('update:viewpoint', option)"
    >
      {{ t(`labels.fleetchartApp.viewpointOptions.${option}`) }}
    </Btn>
    <Btn
      v-tooltip="t('labels.fleetchartApp.rotateShip')"
      :aria-label="t('labels.fleetchartApp.rotateShip')"
      data-test="fleetchart-rotate-ship"
      size="sm"
      @click="emit('rotate')"
    >
      <i class="fa-duotone fa-rotate-right" />
    </Btn>
  </div>
</template>

<style lang="scss" scoped>
@import "index.scss";
</style>
