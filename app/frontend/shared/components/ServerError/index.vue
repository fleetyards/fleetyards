<script lang="ts">
export default {
  name: "ServerError",
};
</script>

<script lang="ts" setup>
import Box from "@/shared/components/Box/index.vue";
import Text from "@/shared/components/base/Text/index.vue";
import { HeadingSizeEnum } from "@/shared/components/base/Heading/types";
import { useI18n } from "@/shared/composables/useI18n";
import { PanelVariantsEnum } from "@/shared/components/base/Panel/types";

const { t } = useI18n();
</script>

<template>
  <Box
    :variant="PanelVariantsEnum.ERROR"
    :heading-size="HeadingSizeEnum.HERO"
    animated
    large
  >
    <template #heading>
      {{ t("headlines.serverError") }}
    </template>
    <template #default>
      <Text>{{ t("texts.serverError") }}</Text>
    </template>
  </Box>
</template>
