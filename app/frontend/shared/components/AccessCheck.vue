<script lang="ts">
export default {
  name: "AccessCheck",
};
</script>

<script lang="ts" setup>
import NotAuthorized from "@/shared/components/NotAuthorized/index.vue";
import { checkAccess } from "@/shared/utils/Access";

type Props = {
  resourceAccess?: string[];
};

const props = defineProps<Props>();

const route = useRoute();

const accessDenied = computed(() => {
  return !checkAccess(props.resourceAccess, route.meta.access);
});
</script>

<template>
  <slot v-if="accessDenied" name="denied">
    <NotAuthorized />
  </slot>
  <slot v-else name="granted"></slot>
</template>
