<script lang="ts">
export default {
  name: "AdminUsersPage",
};
</script>

<script lang="ts" setup>
import { useI18n } from "@/shared/composables/useI18n";
import Heading from "@/shared/components/base/Heading/index.vue";

const { t } = useI18n();
</script>

<template>
  <Heading>{{ t("headlines.admin.users.index") }}</Heading>
</template>
