<script lang="ts">
export default {
  name: "FeatureGuard",
};
</script>

<script lang="ts" setup>
import NotFound from "@/shared/components/NotFound/index.vue";
import { useFeatures } from "@/frontend/composables/useFeatures";

type Props = {
  feature: string;
};

const props = defineProps<Props>();

const { isFeatureEnabled } = useFeatures();

const enabled = computed(() => isFeatureEnabled(props.feature));
</script>

<template>
  <slot v-if="enabled"></slot>
  <NotFound v-else />
</template>
