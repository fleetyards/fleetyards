<script lang="ts">
export default {
  name: "SupportBtn",
};
</script>

<script lang="ts" setup>
import Btn from "@/shared/components/base/Btn/index.vue";
import { BtnSizesEnum } from "@/shared/components/base/Btn/types";

import { useComlink } from "@/shared/composables/useComlink";
import { useI18n } from "@/shared/composables/useI18n";

type Props = {
  size?: `${BtnSizesEnum}`;
};

withDefaults(defineProps<Props>(), {
  size: undefined,
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
  <Btn class="support-button" :size="size" @click="open">
    {{ t("actions.supportUs") }}
  </Btn>
</template>
