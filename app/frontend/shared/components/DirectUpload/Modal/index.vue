<script lang="ts">
export default {
  name: "DirectUploadModal",
};
</script>

<script lang="ts" setup>
import { useI18n } from "@/shared/composables/useI18n";
import Modal from "@/shared/components/AppModal/Inner/index.vue";
import DirectUploadUploader from "@/shared/components/DirectUpload/Uploader/index.vue";
import DirectUploadActions from "@/shared/components/DirectUpload/Actions/index.vue";

const { t } = useI18n();

const uploader = ref<InstanceType<typeof DirectUploadUploader>>();
</script>

<template>
  <Modal>
    <template #title>
      {{ t("directUpload.title") }}
    </template>

    <DirectUploadUploader ref="uploader" multiple />

    <template #footer>
      <DirectUploadActions v-if="uploader" :uploader="uploader" />
    </template>
  </Modal>
</template>

<style lang="scss" scoped>
@import "index";
</style>
