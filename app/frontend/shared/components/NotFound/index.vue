<script lang="ts">
export default {
  name: "NotFound",
};
</script>

<script lang="ts" setup>
import Btn from "@/shared/components/base/Btn/index.vue";
import Box from "@/shared/components/Box/index.vue";
import Text from "@/shared/components/base/Text/index.vue";
import { useI18n } from "@/shared/composables/useI18n";
import { PanelVariantsEnum } from "@/shared/components/base/Panel/types";
import { HeadingSizeEnum } from "@/shared/components/base/Heading/types";

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
      {{ t("headlines.notFound") }}
    </template>
    <template #default>
      <Text>{{ t("texts.notFound") }}</Text>
    </template>
    <template #footer>
      <Btn :to="{ name: 'home' }" :exact="true">
        <i class="fa fa-chevron-left" />
        {{ t("actions.backToHome").toUpperCase() }}
      </Btn>
    </template>
  </Box>
</template>
