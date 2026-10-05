<script lang="ts">
export default {
  name: "AdminFeatureHistoryPage",
};
</script>

<script lang="ts" setup>
import { type Feature } from "@/services/fyAdminApi";
import Panel from "@/shared/components/base/Panel/index.vue";
import PanelBody from "@/shared/components/base/Panel/Body/index.vue";
import FeatureHistory from "@/admin/components/FeatureHistory/index.vue";

type Props = {
  feature: Feature;
};

defineProps<Props>();
</script>

<template>
  <Panel>
    <PanelBody>
      <FeatureHistory :name="feature.name" />
    </PanelBody>
  </Panel>
</template>
