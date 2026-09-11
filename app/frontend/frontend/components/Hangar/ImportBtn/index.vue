<script lang="ts">
export default {
  name: "HangarImportBtn",
};
</script>

<script lang="ts" setup>
import Btn from "@/shared/components/base/Btn/index.vue";
import { useI18n } from "@/shared/composables/useI18n";
import { useComlink } from "@/shared/composables/useComlink";
import {
  BtnSizesEnum,
  BtnVariantsEnum,
} from "@/shared/components/base/Btn/types";

type Props = {
  variant?: BtnVariantsEnum;
  size?: BtnSizesEnum;
};

withDefaults(defineProps<Props>(), {
  variant: undefined,
  size: undefined,
});

const { t } = useI18n();

const comlink = useComlink();

const openModal = () => {
  comlink.emit("open-modal", {
    component: () =>
      import("@/frontend/components/Hangar/ImportBtn/Modal/index.vue"),
  });
};
</script>

<template>
  <Btn
    :size="size"
    :variant="variant"
    :aria-label="t('actions.import')"
    @click="openModal"
  >
    <i class="fa-light fa-upload" />
    <span>
      {{ t("actions.import") }}
    </span>
  </Btn>
</template>
