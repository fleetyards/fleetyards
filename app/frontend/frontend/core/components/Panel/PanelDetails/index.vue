<template>
  <div v-show-slide:400:ease-in-out="visible" class="panel-details">
    <slot />
  </div>
</template>

<script lang="ts" setup>
type Props = {
  visible: boolean;
};

withDefaults(defineProps<Props>(), {
  visible: false,
});
</script>

<script lang="ts">
export default {
  name: "PanelDetails",
};
</script>
