<script lang="ts">
export default {
  name: "AdminAccessCheck",
};
</script>

<script lang="ts" setup>
import NotAuthorized from "@/shared/components/NotAuthorized/index.vue";
import { checkAccess } from "@/shared/utils/Access";

type Props = {
  resourceAccess?: string[];
  superAdmin?: boolean;
};

const props = defineProps<Props>();

const route = useRoute();

const accessDenied = computed(() => {
  return (
    !checkAccess(props.resourceAccess, route.meta.access) && !props.superAdmin
  );
});
</script>

<template>
  <slot v-if="accessDenied" name="denied">
    <NotAuthorized />
  </slot>
  <slot v-else name="granted"></slot>
</template>
