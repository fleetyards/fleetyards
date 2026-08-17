<script lang="ts">
export default {
  name: "SupportBtn",
};
</script>

<script lang="ts" setup>
import Btn from "@/shared/components/base/Btn/index.vue";
import {
  BtnSizesEnum,
  BtnVariantsEnum,
} from "@/shared/components/base/Btn/types";

import { useComlink } from "@/shared/composables/useComlink";
import { useI18n } from "@/shared/composables/useI18n";

type Props = {
  size?: `${BtnSizesEnum}`;
  variant?: `${BtnVariantsEnum}`;
};

withDefaults(defineProps<Props>(), {
  size: undefined,
  variant: undefined,
});

const { t } = useI18n();

const comlink = useComlink();

const open = () => {
  comlink.emit("open-modal", {
    component: () => import("@/frontend/components/SupportBtn/Modal/index.vue"),
    wide: true,
  });
};
</script>

<template>
  <!-- Slotted so the footer can keep its own label and heart without a second
       copy of the modal-opening logic; the default is what every other caller
       already showed. -->
  <Btn class="support-button" :size="size" :variant="variant" @click="open">
    <slot>{{ t("actions.supportUs") }}</slot>
  </Btn>
</template>
