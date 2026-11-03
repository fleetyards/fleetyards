<script lang="ts">
export default {
  name: "CompareBtn",
};
</script>

<script lang="ts" setup>
import type { RouteLocationRaw } from "vue-router";
import Btn from "@/shared/components/base/Btn/index.vue";
import { BtnSizesEnum } from "@/shared/components/base/Btn/types";
import { useI18n } from "@/shared/composables/useI18n";

type Props = {
  to: RouteLocationRaw;
};

defineProps<Props>();

const { t } = useI18n();
</script>

<template>
  <Teleport to="#header-right">
    <Btn :to="to" :size="BtnSizesEnum.MD" data-test="compare">
      <i class="fa-light fa-code-compare" aria-hidden="true" />
      <span>{{ t("actions.compare.item") }}</span>
    </Btn>
  </Teleport>
</template>
