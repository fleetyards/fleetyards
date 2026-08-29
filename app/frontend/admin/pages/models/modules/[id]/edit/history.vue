<script lang="ts">
export default {
  name: "AdminModelModuleEditHistoryPage",
};
</script>

<script lang="ts" setup>
import { useI18n } from "@/shared/composables/useI18n";
import Heading from "@/shared/components/base/Heading/index.vue";
import { type ModelModule } from "@/services/fyAdminApi";
import VersionHistory from "@/admin/components/VersionHistory/index.vue";

type Props = {
  modelModule: ModelModule;
};

const props = defineProps<Props>();

const { t } = useI18n();
</script>

<template>
  <Heading hero class="mb-4">{{
    t("headlines.admin.modelModules.history")
  }}</Heading>

  <VersionHistory :item-id="props.modelModule.id" item-type="ModelModule" />
</template>
