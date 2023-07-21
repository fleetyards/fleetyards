<template>
  <div>
    <slot v-if="isError" name="error">
      <NotFound />
    </slot>
    <slot v-else-if="isLoading" name="loading">
      <Loader v-if="showSpinner" :loading="true" />
    </slot>
    <slot v-else name="resolved"></slot>
  </div>
</template>

<script lang="ts" setup>
import NotFound from "@/frontend/core/components/NotFound/index.vue";
import Loader from "@/frontend/core/components/Loader/index.vue";

type Props = {
  isError?: boolean;
  isLoading?: boolean;
  showSpinner?: boolean;
};

withDefaults(defineProps<Props>(), {
  isError: false,
  isLoading: true,
  showSpinner: true,
});
</script>

<script lang="ts">
export default {
  name: "AsyncData",
};
</script>
