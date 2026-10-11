<script lang="ts">
export default {
  name: "PaginatorAboveList",
};
</script>

<script lang="ts" setup>
import { PAGINATOR_ABOVE_LIST } from "@/shared/components/Paginator/placement";

provide(PAGINATOR_ABOVE_LIST, true);
</script>

<template>
  <slot />
</template>
