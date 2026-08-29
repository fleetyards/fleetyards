<script lang="ts">
export default {
  name: "AdminComponentEditHistoryPage",
};
</script>

<script lang="ts" setup>
import { useI18n } from "@/shared/composables/useI18n";
import Heading from "@/shared/components/base/Heading/index.vue";
import { type Component } from "@/services/fyAdminApi";
import VersionHistory from "@/admin/components/VersionHistory/index.vue";

type Props = {
  component: Component;
};

const props = defineProps<Props>();

const { t } = useI18n();
</script>

<template>
  <Heading hero class="mb-4">{{
    t("headlines.admin.components.edit.history")
  }}</Heading>

  <VersionHistory :item-id="props.component.id" item-type="Component" />
</template>
