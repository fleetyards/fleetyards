<script lang="ts">
export default {
  name: "AdminAccessCheck",
};
</script>

<script lang="ts" setup>
import NotAuthorized from "@/shared/components/NotAuthorized/index.vue";
import Loader from "@/shared/components/Loader/index.vue";
import { checkAccess } from "@/shared/utils/Access";

type Props = {
  resourceAccess?: string[];
  superAdmin?: boolean;
  loading?: boolean;
};

const props = withDefaults(defineProps<Props>(), {
  resourceAccess: undefined,
  superAdmin: false,
  loading: false,
});

const route = useRoute();

const accessDenied = computed(() => {
  return (
    !checkAccess(props.resourceAccess, route.meta.access) && !props.superAdmin
  );
});
</script>

<template>
  <slot v-if="loading" name="loading">
    <Loader :loading="true" />
  </slot>
  <slot v-else-if="accessDenied" name="denied">
    <NotAuthorized />
  </slot>
  <slot v-else name="granted"></slot>
</template>
