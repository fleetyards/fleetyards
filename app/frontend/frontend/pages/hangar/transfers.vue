<script lang="ts">
export default {
  name: "HangarTransfersPage",
};
</script>

<script lang="ts" setup>
import type { Crumb } from "@/shared/components/BreadCrumbs/types";
import TransfersView from "@/frontend/components/Logistics/TransfersView/index.vue";
import { useI18n } from "@/shared/composables/useI18n";

const { t } = useI18n();

const crumbs = computed<Crumb[]>(() => [
  { to: { name: "hangar" }, label: t("nav.hangar.index") },
  { to: { name: "hangar-inventories" }, label: t("nav.hangar.inventories") },
]);
</script>

<template>
  <TransfersView :crumbs="crumbs" />
</template>
