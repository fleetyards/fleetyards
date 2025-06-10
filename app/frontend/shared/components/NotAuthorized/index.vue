<script lang="ts">
export default {
  name: "NotAuthorized",
};
</script>

<script lang="ts" setup>
import { PanelVariantsEnum } from "@/shared/components/base/Panel/types";
import { HeadingLevelEnum } from "@/shared/components/base/Heading/types";
import { useI18n } from "@/shared/composables/useI18n";
import Btn from "@/shared/components/base/Btn/index.vue";
import Box from "@/shared/components/Box/index.vue";
import Heading from "@/shared/components/base/Heading/index.vue";
import Text from "@/shared/components/base/Text/index.vue";

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
      {{ t("headlines.accessDenied") }}
    </template>
    <template #default>
      <Text>{{ t("texts.accessDenied") }}</Text>
    </template>
    <template #footer>
      <Btn :to="{ name: 'home' }" :exact="true">
        <i class="fa fa-chevron-left" />
        {{ t("actions.backToHome").toUpperCase() }}
      </Btn>
    </template>
  </Box>
</template>
