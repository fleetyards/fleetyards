<template>
  <div
    :class="{
      'box-large': large,
    }"
    class="box"
  >
    <Panel>
      <div class="box-inner">
        <slot />
      </div>
    </Panel>
    <slot name="footer" />
  </div>
</template>

<script lang="ts" setup>
import Panel from "@/frontend/core/components/Panel/index.vue";

type Props = {
  large: boolean;
};

withDefaults(defineProps<Props>(), {
  large: false,
});
</script>

<script lang="ts">
export default {
  name: "BaseBox",
};
</script>
