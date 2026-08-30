<script lang="ts">
export default {
  name: "AdminModelEditHistoryPage",
};
</script>

<script lang="ts" setup>
import { useI18n } from "@/shared/composables/useI18n";
import Heading from "@/shared/components/base/Heading/index.vue";
import { type ModelExtended } from "@/services/fyAdminApi";
import VersionHistory from "@/admin/components/VersionHistory/index.vue";

type Props = {
  model: ModelExtended;
};

const props = defineProps<Props>();

const { t } = useI18n();
</script>

<template>
  <Heading hero class="mb-4">{{
    t("headlines.admin.models.edit.history")
  }}</Heading>

  <VersionHistory :item-id="props.model.id" item-type="Model" />
</template>
