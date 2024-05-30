<script lang="ts">
export default {
  name: "NotFound",
};
</script>

<script lang="ts" setup>
import Btn from "@/shared/components/base/Btn/index.vue";
import Box from "@/shared/components/base/Box/index.vue";
import Heading from "@/shared/components/base/Heading/index.vue";
import Text from "@/shared/components/base/Text/index.vue";
import { useI18n } from "@/shared/composables/useI18n";
import { PanelVariantsEnum } from "@/shared/components/Panel/types";

const { t } = useI18n();
</script>

<template>
  <Box :variant="PanelVariantsEnum.ERROR" large>
    <Heading level="h1">{{ t("headlines.notFound") }}</Heading>
    <Text>{{ t("texts.notFound") }}</Text>
    <template #footer>
      <Btn :to="{ name: 'home' }" :exact="true">
        <i class="fa fa-chevron-left" />
        {{ t("actions.backToHome").toUpperCase() }}
      </Btn>
    </template>
  </Box>
</template>
