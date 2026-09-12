<script lang="ts">
export default {
  name: "AdminModelEditDocksPage",
};
</script>

<script lang="ts" setup>
import DocksEditor from "@/admin/components/Docks/Editor/index.vue";
import { useI18n } from "@/shared/composables/useI18n";
import { type ModelExtended } from "@/services/fyAdminApi";

interface Props {
  model: ModelExtended;
}

defineProps<Props>();

const { t } = useI18n();
</script>

<template>
  <DocksEditor
    :parent-id="model.id"
    parent-type="Model"
    :headline="t('headlines.admin.models.edit.docks')"
  />
</template>
