<script lang="ts">
export default {
  name: "BaseBox",
};
</script>

<script lang="ts" setup>
import Panel from "@/shared/components/Panel/index.vue";

type Props = {
  large?: boolean;
};

withDefaults(defineProps<Props>(), {
  large: false,
});
</script>

<template>
  <div
    :class="{
      'box-large': large,
    }"
    class="box"
  >
    <Panel slim>
      <div class="box-inner">
        <slot />
      </div>
    </Panel>
    <slot name="footer" />
  </div>
</template>

<style lang="scss" scoped>
@import "./index.scss";
</style>
