<template>
  <section :class="cssClasses">
    <slot v-if="error" name="error">
      <NotFound />
    </slot>
    <slot v-else-if="loading" name="loading">
      <Loader v-if="showSpinner" :loading="true" />
    </slot>
    <slot v-else name="resolved"></slot>
  </section>
</template>

<script lang="ts" setup>
import NotFound from "@/shared/components/NotFound/index.vue";
import Loader from "@/shared/components/Loader/index.vue";

export type AsyncStatus = {
  fetchStatus: Ref<string>;
  isError: Ref<boolean>;
  isLoading: Ref<boolean>;
  isFetching: Ref<boolean>;
  isRefetching: Ref<boolean>;
};

type Props = {
  asyncStatus: AsyncStatus;
  showSpinner?: boolean;
  fullscreen?: boolean;
};

const props = withDefaults(defineProps<Props>(), {
  showSpinner: true,
  fullscreen: true,
});

const route = useRoute();

const cssClasses = computed(() => {
  return {
    "container main": props.fullscreen,
    [route.name as string]: props.fullscreen,
  };
});

const error = computed(() => {
  return props.asyncStatus.isError.value;
});

const loading = computed(() => {
  return (
    (props.asyncStatus.isFetching.value || props.asyncStatus.isLoading.value) &&
    !props.asyncStatus.isRefetching.value
  );
});
</script>

<script lang="ts">
export default {
  name: "AsyncData",
};
</script>
