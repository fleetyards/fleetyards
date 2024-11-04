<script lang="ts">
export default {
  name: "BaseBox",
};
</script>

<script lang="ts" setup>
import Panel from "@/shared/components/Panel/index.vue";
import { PanelVariantsEnum } from "@/shared/components/Panel/types";

type Props = {
  large?: boolean;
  variant?: PanelVariantsEnum;
};

withDefaults(defineProps<Props>(), {
  large: false,
  variant: undefined,
});
</script>

<template>
  <div
    :class="{
      'box-large': large,
    }"
    class="box"
  >
    <Panel :variant="variant" slim>
      <div class="box-inner">
        <slot />
      </div>
    </Panel>
    <slot name="footer" />
  </div>
</template>

<style lang="scss" scoped>
@import "index";
</style>
