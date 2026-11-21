<script lang="ts">
export default {
  name: "BlueprintLogImportBtn",
};
</script>

<script lang="ts" setup>
import Btn from "@/shared/components/base/Btn/index.vue";
import { BtnSizesEnum } from "@/shared/components/base/Btn/types";
import { useI18n } from "@/shared/composables/useI18n";
import { useComlink } from "@/shared/composables/useComlink";
import { useFeatures } from "@/frontend/composables/useFeatures";
import { FeatureFlagName } from "@/services/fyApi";

const { t } = useI18n();

const comlink = useComlink();

const { isFeatureEnabled } = useFeatures();

const openModal = () => {
  comlink.emit("open-modal", {
    component: () =>
      import("@/frontend/components/Blueprints/LogImport/Modal/index.vue"),
  });
};
</script>

<template>
  <Btn
    v-if="isFeatureEnabled(FeatureFlagName.BLUEPRINT_LOG_IMPORT)"
    :size="BtnSizesEnum.SM"
    data-test="open-blueprint-log-import"
    @click="openModal"
  >
    <i class="fa-light fa-file-import" />
    <span>{{ t("actions.blueprintLogImport.open") }}</span>
  </Btn>
</template>
