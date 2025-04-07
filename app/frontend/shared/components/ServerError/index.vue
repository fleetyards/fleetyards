<script lang="ts">
export default {
  name: "ServerError",
};
</script>

<script lang="ts" setup>
import Box from "@/shared/components/Box/index.vue";
import Heading from "@/shared/components/base/Heading/index.vue";
import Text from "@/shared/components/base/Text/index.vue";
import { HeadingLevelEnum } from "@/shared/components/base/Heading/types";
import { useI18n } from "@/shared/composables/useI18n";
import { PanelVariantsEnum } from "@/shared/components/base/Panel/types";

const { t } = useI18n();
</script>

<template>
  <Box :variant="PanelVariantsEnum.ERROR" large>
    <Heading :level="HeadingLevelEnum.H1">{{
      t("headlines.serverError")
    }}</Heading>
    <Text>{{ t("texts.serverError") }}</Text>
  </Box>
</template>
