<template>
  <router-link :to="to" :aria-label="label" class="panel-link" />
</template>

<script lang="ts" setup>
import type { RouteLocationRaw } from "vue-router";

type Props = {
  to: RouteLocationRaw;
  label: string;
};

defineProps<Props>();
</script>

<script lang="ts">
export default {
  name: "PanelLink",
};
</script>

<style lang="scss" scoped>
@import "index";
</style>
