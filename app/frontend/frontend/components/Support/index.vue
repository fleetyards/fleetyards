<template>
  <Btn size="small" class="support-button" @click="open">
    {{ t("actions.supportUs") }}
  </Btn>
</template>

<script lang="ts" setup>
import Btn from "@/shared/components/base/Btn/index.vue";
import { useComlink } from "@/shared/composables/useComlink";
import { useI18n } from "@/shared/composables/useI18n";

const { t } = useI18n();

const comlink = useComlink();

const open = () => {
  comlink.emit("open-modal", {
    component: () => import("@/frontend/components/Support/Modal/index.vue"),
    wide: true,
  });
};
</script>

<script lang="ts">
export default {
  name: "SupportBtn",
};
</script>

<style lang="scss" scoped>
@import "./index.scss";
</style>
