<template>
  <Heading>{{ t("headlines.admin.dashboard") }}</Heading>
</template>

<script lang="ts" setup>
import Heading from "@/shared/components/base/Heading/index.vue";
import { useI18n } from "@/shared/composables/useI18n";

const { t } = useI18n();
</script>

<script lang="ts">
export default {
  name: "AdminHomePage",
};
</script>
