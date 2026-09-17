<script lang="ts">
export default {
  name: "SettingsDonationsPage",
};
</script>

<script lang="ts" setup>
import BreadCrumbs from "@/shared/components/BreadCrumbs/index.vue";
import { type Crumb } from "@/shared/components/BreadCrumbs/types";
import Heading from "@/shared/components/base/Heading/index.vue";
import SupporterNomination from "@/frontend/components/SupporterNomination/index.vue";
import { useI18n } from "@/shared/composables/useI18n";

const { t } = useI18n();

const crumbs = computed<Crumb[]>(() => [
  {
    to: { name: "settings-profile" },
    label: t("nav.settings.index"),
  },
]);
</script>

<template>
  <BreadCrumbs :crumbs="crumbs" />
  <Heading hero>{{ t("headlines.settings.donations") }}</Heading>

  <SupporterNomination />
</template>
