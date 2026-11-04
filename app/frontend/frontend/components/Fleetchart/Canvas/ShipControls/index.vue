<script lang="ts">
export default {
  name: "FleetchartCanvasShipControls",
};
</script>

<script lang="ts" setup>
import Btn from "@/shared/components/base/Btn/index.vue";
import BtnDropdown from "@/shared/components/base/BtnDropdown/index.vue";
import { useI18n } from "@/shared/composables/useI18n";
import {
  FleetchartFacings,
  FleetchartViewpoints,
} from "@/shared/stores/fleetchart";

interface Props {
  count: number;
  // Undefined when the selected ships differ.
  viewpoint?: FleetchartViewpoints;
  available: FleetchartViewpoints[];
  facing?: FleetchartFacings;
  canGroup?: boolean;
  canUngroup?: boolean;
}

withDefaults(defineProps<Props>(), {
  viewpoint: undefined,
  facing: undefined,
  canGroup: false,
  canUngroup: false,
});

const emit = defineEmits<{
  "update:viewpoint": [viewpoint: FleetchartViewpoints];
  "update:facing": [facing: FleetchartFacings];
  stack: [direction: "front" | "back"];
  group: [];
  ungroup: [];
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
    <span v-if="count > 1" class="fleetchart-canvas-ship-controls__count">
      {{ count }}
    </span>

    <BtnDropdown data-test="fleetchart-ship-view">
      <template #label>
        {{
          viewpoint
            ? t(`labels.fleetchartApp.viewpointOptions.${viewpoint}`)
            : t("labels.fleetchartApp.viewpoint")
        }}
      </template>
      <Btn
        v-for="option in FleetchartViewpoints"
        :key="option"
        :active="viewpoint === option"
        :disabled="!available.includes(option)"
        :data-test="`fleetchart-ship-view-${option}`"
        variant="bare"
        @click="emit('update:viewpoint', option)"
      >
        {{ t(`labels.fleetchartApp.viewpointOptions.${option}`) }}
      </Btn>
    </BtnDropdown>

    <BtnDropdown data-test="fleetchart-ship-facing">
      <template #label>
        {{
          facing
            ? t(`labels.fleetchartApp.facingOptions.${facing}`)
            : t("labels.fleetchartApp.facing")
        }}
      </template>
      <Btn
        v-for="option in FleetchartFacings"
        :key="option"
        :active="facing === option"
        :data-test="`fleetchart-ship-facing-${option}`"
        variant="bare"
        @click="emit('update:facing', option)"
      >
        {{ t(`labels.fleetchartApp.facingOptions.${option}`) }}
      </Btn>
    </BtnDropdown>

    <Btn
      v-tooltip="t('labels.fleetchartApp.bringToFront')"
      :aria-label="t('labels.fleetchartApp.bringToFront')"
      data-test="fleetchart-bring-to-front"
      @click="emit('stack', 'front')"
    >
      <i class="fa-duotone fa-bring-front" />
    </Btn>
    <Btn
      v-tooltip="t('labels.fleetchartApp.sendToBack')"
      :aria-label="t('labels.fleetchartApp.sendToBack')"
      data-test="fleetchart-send-to-back"
      @click="emit('stack', 'back')"
    >
      <i class="fa-duotone fa-send-back" />
    </Btn>

    <Btn
      v-if="canGroup"
      v-tooltip="t('labels.fleetchartApp.groupShips')"
      :aria-label="t('labels.fleetchartApp.groupShips')"
      data-test="fleetchart-group-ships"
      @click="emit('group')"
    >
      <i class="fa-duotone fa-object-group" />
    </Btn>
    <Btn
      v-if="canUngroup"
      v-tooltip="t('labels.fleetchartApp.ungroupShips')"
      :aria-label="t('labels.fleetchartApp.ungroupShips')"
      data-test="fleetchart-ungroup-ships"
      @click="emit('ungroup')"
    >
      <i class="fa-duotone fa-object-ungroup" />
    </Btn>
  </div>
</template>

<style lang="scss" scoped>
@import "index.scss";
</style>
