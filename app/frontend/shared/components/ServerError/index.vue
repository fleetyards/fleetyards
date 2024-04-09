<script lang="ts">
export default {
  name: "ServerError",
};
</script>

<script lang="ts" setup>
import Box from "@/shared/components/base/Box/index.vue";
import { useI18n } from "@/shared/composables/useI18n";
import { PanelVariantsEnum } from "@/shared/components/Panel/types";

const { t } = useI18n();
</script>

<template>
  <Box :variant="PanelVariantsEnum.ERROR" large>
    <h1>{{ t("headlines.serverError") }}</h1>
    <p>{{ t("texts.serverError") }}</p>
  </Box>
</template>
