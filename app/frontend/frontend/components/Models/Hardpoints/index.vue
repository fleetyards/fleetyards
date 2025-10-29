<script lang="ts">
export default {
  name: "ModelHardpoints",
};
</script>

<script lang="ts" setup>
import Hardpoints from "@/frontend/components/Models/Hardpoints/new.vue";
import OldHardpoints from "@/frontend/components/Models/Hardpoints/old.vue";
import { useFeatures } from "@/frontend/composables/useFeatures";
import type { Model } from "@/services/fyApi";

type Props = {
  model: Model;
};

defineProps<Props>();

const { isFeatureEnabled } = useFeatures();
</script>

<template>
  <Hardpoints v-if="isFeatureEnabled('hardpoints-v2')" :model="model" />
  <OldHardpoints v-else :model="model" />
</template>
