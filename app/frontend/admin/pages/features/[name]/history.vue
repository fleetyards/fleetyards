<script lang="ts">
export default {
  name: "AdminFeatureHistoryPage",
};
</script>

<script lang="ts" setup>
import { type Feature } from "@/services/fyAdminApi";
import Panel from "@/shared/components/base/Panel/index.vue";
import FeatureHistory from "@/admin/components/FeatureHistory/index.vue";

type Props = {
  feature: Feature;
};

defineProps<Props>();
</script>

<template>
  <Panel>
    <FeatureHistory :name="feature.name" />
  </Panel>
</template>
