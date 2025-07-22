<script lang="ts">
export default {
  name: "BasePanelLink",
};
</script>

<script lang="ts" setup>
import type { RouteLocationRaw } from "vue-router";

type Props = {
  to: RouteLocationRaw;
  label: string;
};

defineProps<Props>();
</script>

<template>
  <router-link :to="to" :aria-label="label" class="panel-link" />
</template>

<style lang="scss" scoped>
@import "index";
</style>
