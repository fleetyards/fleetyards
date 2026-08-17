<script lang="ts">
export default {
  name: "Forbidden",
};
</script>

<script lang="ts" setup>
import Btn from "@/shared/components/base/Btn/index.vue";
import Box from "@/shared/components/Box/index.vue";
import Text from "@/shared/components/base/Text/index.vue";
import { useI18n } from "@/shared/composables/useI18n";
import { PanelTonesEnum } from "@/shared/components/base/Panel/types";
import { HeadingSizeEnum } from "@/shared/components/base/Heading/types";

const { t } = useI18n();
</script>

<template>
  <Box
    :tone="PanelTonesEnum.ERROR"
    :heading-size="HeadingSizeEnum.HERO"
    animated
    large
  >
    <template #heading>
      {{ t("headlines.forbidden") }}
    </template>
    <template #default>
      <Text>{{ t("texts.forbidden") }}</Text>
    </template>
    <template #footer>
      <Btn :to="{ name: 'home' }">
        <i class="fa fa-chevron-left" />
        {{ t("actions.backToHome").toUpperCase() }}
      </Btn>
    </template>
  </Box>
</template>
