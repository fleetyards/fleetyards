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

const { t } = useI18n();

const comlink = useComlink();

const openModal = () => {
  comlink.emit("open-modal", {
    component: () =>
      import("@/frontend/components/Blueprints/LogImport/Modal/index.vue"),
  });
};
</script>

<template>
  <Btn
    :size="BtnSizesEnum.SM"
    data-test="open-blueprint-log-import"
    @click="openModal"
  >
    <i class="fa-light fa-file-import" />
    <span>{{ t("actions.blueprintLogImport.open") }}</span>
  </Btn>
</template>
