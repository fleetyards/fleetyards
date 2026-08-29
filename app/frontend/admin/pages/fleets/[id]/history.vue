<script lang="ts">
export default {
  name: "AdminFleetHistoryPage",
};
</script>

<script lang="ts" setup>
import { useI18n } from "@/shared/composables/useI18n";
import Heading from "@/shared/components/base/Heading/index.vue";
import { type Fleet } from "@/services/fyAdminApi";
import VersionHistory from "@/admin/components/VersionHistory/index.vue";

type Props = {
  fleet: Fleet;
};

const props = defineProps<Props>();

const { t } = useI18n();
</script>

<template>
  <Heading hero class="mb-4">{{ t("headlines.admin.fleets.history") }}</Heading>

  <VersionHistory :item-id="props.fleet.id" item-type="Fleet" />
</template>
