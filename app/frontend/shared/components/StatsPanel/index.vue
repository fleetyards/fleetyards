<script lang="ts" setup>
import Panel from "@/shared/components/Panel/index.vue";
import { PanelVariantsEnum } from "@/shared/components/Panel/types";

type Props = {
  label: string;
  icon: string;
  value: number;
  outerSpacing?: boolean;
};

withDefaults(defineProps<Props>(), {
  outerSpacing: true,
});
</script>

<script lang="ts">
export default {
  name: "StatsPanel",
};
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
        {{ value }}
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
