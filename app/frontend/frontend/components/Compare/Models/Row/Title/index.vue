<script lang="ts">
export default {
  name: "CompareModelsRowTitle",
};
</script>

<script lang="ts" setup>
type Props = {
  title: string;
  active?: boolean;
};

const props = withDefaults(defineProps<Props>(), {
  active: false,
});
</script>

<template>
  <div class="title" :class="{ active: props.active }">
    {{ props.title }}
    <i class="fa fa-chevron-right" />
  </div>
</template>

<style lang="scss" scoped>
@import "index";
</style>
