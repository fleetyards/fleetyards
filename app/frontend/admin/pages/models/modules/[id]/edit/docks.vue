<script lang="ts">
export default {
  name: "AdminModelModuleEditDocksPage",
};
</script>

<script lang="ts" setup>
import DocksEditor from "@/admin/components/Docks/Editor/index.vue";
import { useI18n } from "@/shared/composables/useI18n";
import { type ModelModule } from "@/services/fyAdminApi";

type Props = {
  modelModule: ModelModule;
};

defineProps<Props>();

const { t } = useI18n();
</script>

<template>
  <DocksEditor
    :parent-id="modelModule.id"
    parent-type="ModelModule"
    :headline="t('headlines.admin.modelModules.docks')"
  />
</template>
