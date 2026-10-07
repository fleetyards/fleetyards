<script lang="ts">
export default {
  name: "HangarBuybackSyncBtn",
};
</script>

<script lang="ts" setup>
import Btn from "@/shared/components/base/Btn/index.vue";
import { useI18n } from "@/shared/composables/useI18n";
import { useComlink } from "@/shared/composables/useComlink";
import { useMobile } from "@/shared/composables/useMobile";
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

const mobile = useMobile();

const comlink = useComlink();

const openModal = () => {
  comlink.emit("open-modal", {
    component: () =>
      import("@/frontend/components/Hangar/BuybackSyncBtn/Modal/index.vue"),
    fixed: true,
  });
};
</script>

<template>
  <Btn
    v-if="!mobile"
    :size="size"
    :variant="variant"
    :aria-label="t('actions.syncRsiBuybacks')"
    data-test="open-buyback-sync"
    @click="openModal"
  >
    <i class="fa-light fa-rotate-left" />
    <span>
      {{ t("actions.syncRsiBuybacks") }}
    </span>
  </Btn>
</template>
