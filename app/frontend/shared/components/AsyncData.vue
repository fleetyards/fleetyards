<template>
  <section :class="cssClasses">
    <slot v-if="error" name="error">
      <NotFound v-if="errorType === ErrorTypesEnum.NOT_FOUND" />
      <ServerError v-else />
    </slot>
    <slot v-else-if="loading" name="loading">
      <Loader v-if="showSpinner" :loading="true" />
    </slot>
    <slot v-else name="resolved"></slot>
  </section>
</template>

<script lang="ts" setup>
import NotFound from "@/shared/components/NotFound/index.vue";
import ServerError from "@/shared/components/ServerError/index.vue";
import Loader from "@/shared/components/Loader/index.vue";
import {
  type AsyncStatus,
  ErrorTypesEnum,
} from "@/shared/components/AsyncData.types";
import { isAxiosError } from "axios";
import { type ApiError } from "@/services/fyApi";

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
  return props.asyncStatus.error?.value;
});

const status = computed(() => {
  if (!error.value) return;

  // AxiosError
  if (isAxiosError(error.value)) {
    return error.value.response?.status;
  }

  // ApiError
  return (error.value as ApiError).status;
});

const errorType = computed(() => {
  if (!status.value) {
    return undefined;
  }

  if (status.value == 404) {
    return ErrorTypesEnum.NOT_FOUND;
  }

  return ErrorTypesEnum.ERROR;
});

const loading = computed(() => {
  return (
    (props.asyncStatus.isFetching?.value ||
      props.asyncStatus.isLoading?.value) &&
    !props.asyncStatus.isRefetching?.value
  );
});
</script>

<script lang="ts">
export default {
  name: "AsyncData",
};
</script>
