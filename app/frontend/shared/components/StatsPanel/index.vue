<script lang="ts">
export default {
  name: "StatsPanel",
};
</script>

<script lang="ts" setup>
import Panel from "@/shared/components/Panel/index.vue";
import { PanelVariantsEnum } from "@/shared/components/Panel/types";
import NumberFlow from "@number-flow/vue";

type Props = {
  label: string;
  icon: string;
  value: number;
  prefix?: string;
  suffix?: string;
  outerSpacing?: boolean;
};

const props = withDefaults(defineProps<Props>(), {
  outerSpacing: true,
  value: undefined,
  prefix: undefined,
  suffix: undefined,
});

const innerValue = computed(() => {
  return props.value;
});

const prefix = computed(() => {
  if (!props.prefix) {
    return undefined;
  }

  return ` ${props.prefix}`;
});

const suffix = computed(() => {
  if (!props.suffix) {
    return undefined;
  }

  return ` ${props.suffix}`;
});
</script>

<template>
  <Panel
    :variant="PanelVariantsEnum.PRIMARY"
    :outer-spacing="outerSpacing"
    slim
  >
    <div class="stats-panel">
      <div class="stats-panel-icon">
        <i :class="icon" />
      </div>
      <div class="stats-panel-text">
        <NumberFlow :value="innerValue" :prefix="prefix" :suffix="suffix" />
        <div class="stats-panel-text-info">
          {{ label }}
        </div>
      </div>
    </div>
  </Panel>
</template>

<style lang="scss" scoped>
@import "index";
</style>
