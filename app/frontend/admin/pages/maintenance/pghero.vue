<script lang="ts" setup>
import EngineFrame from "@/admin/components/EngineFrame/index.vue";
import { engineUrls } from "@/admin/utils/EngineUrls";
import { useI18n } from "@/shared/composables/useI18n";

const { t } = useI18n();
</script>

<template>
  <EngineFrame
    :src="engineUrls.pghero"
    :title="t('nav.admin.maintenance.pghero')"
  />
</template>
