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
import { isAxiosError } from "axios";

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

const status = computed(() => {
  if (!error.value || !isAxiosError(error.value)) return;

  return error.value.response?.status;
});

const errorType = computed(() => {
  if (!status.value) {
    return undefined;
  }

  if (status.value == 404) {
    return ErrorTypesEnum.NOT_FOUND;
  }

  // A refused request is not a broken server: the feature is off, or the record
  // belongs to somebody else. Saying "server error" sends people to report an
  // outage that isn't one.
  if (status.value == 403) {
    return ErrorTypesEnum.FORBIDDEN;
  }

  return ErrorTypesEnum.ERROR;
});

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
