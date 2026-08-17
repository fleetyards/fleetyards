<script lang="ts">
export default {
  name: "AsyncData",
};
</script>

<script lang="ts" setup>
import NotFound from "@/shared/components/NotFound/index.vue";
import Forbidden from "@/shared/components/Forbidden/index.vue";
import ServerError from "@/shared/components/ServerError/index.vue";
import Loader from "@/shared/components/Loader/index.vue";
import {
  type AsyncStatus,
  ErrorTypesEnum,
} from "@/shared/components/AsyncData.types";
import { errorTypeFrom } from "@/shared/utils/ErrorTypes";

type Props = {
  asyncStatus: AsyncStatus;
  showSpinner?: boolean;
  hideError?: boolean;
};

const props = withDefaults(defineProps<Props>(), {
  showSpinner: true,
  hideError: false,
});

const error = computed(() => {
  return props.asyncStatus.error?.value;
});

const errorType = computed(() => errorTypeFrom(error.value));

const loading = computed(() => {
  return (
    (props.asyncStatus.isPending?.value ||
      props.asyncStatus.isFetching?.value ||
      props.asyncStatus.isLoading?.value) &&
    !props.asyncStatus.isRefetching?.value
  );
});
</script>

<template>
  <slot v-if="error && !hideError" name="error">
    <NotFound v-if="errorType === ErrorTypesEnum.NOT_FOUND" />
    <Forbidden v-else-if="errorType === ErrorTypesEnum.FORBIDDEN" />
    <ServerError v-else />
  </slot>
  <slot v-else-if="loading" name="loading">
    <Loader v-if="showSpinner" :loading="true" />
  </slot>
  <slot v-else-if="!error" name="resolved"></slot>
</template>
