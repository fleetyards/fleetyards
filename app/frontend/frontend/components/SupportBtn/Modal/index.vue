<script lang="ts">
export default {
  name: "SupportModal",
};
</script>

<script lang="ts" setup>
import Modal from "@/shared/components/AppModal/Inner/index.vue";
import SupportContent from "@/frontend/components/SupportContent/index.vue";
import { useI18n } from "@/shared/composables/useI18n";

const { t } = useI18n();
</script>

<template>
  <Modal :title="t('headlines.support')">
    <SupportContent />
  </Modal>
</template>
