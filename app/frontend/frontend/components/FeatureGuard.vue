<script lang="ts">
export default {
  name: "FeatureGuard",
};
</script>

<script lang="ts" setup>
import Box from "@/shared/components/Box/index.vue";
import Text from "@/shared/components/base/Text/index.vue";
import { useI18n } from "@/shared/composables/useI18n";
import { useFeatures } from "@/frontend/composables/useFeatures";
import { PanelVariantsEnum } from "@/shared/components/base/Panel/types";
import { HeadingSizeEnum } from "@/shared/components/base/Heading/types";

type Props = {
  feature: string;
};

const props = defineProps<Props>();

const { t } = useI18n();
const { isFeatureEnabled } = useFeatures();

const enabled = computed(() => isFeatureEnabled(props.feature));
</script>

<template>
  <slot v-if="enabled"></slot>
  <Box
    v-else
    :variant="PanelVariantsEnum.PRIMARY"
    :heading-size="HeadingSizeEnum.HERO"
    large
  >
    <template #heading>
      {{ t("headlines.featureNotReady") }}
    </template>
    <template #default>
      <Text>{{ t("texts.featureNotReady") }}</Text>
    </template>
    <template #footer>
      <Btn :to="{ name: 'home' }" :exact="true">
        <i class="fa fa-chevron-left" />
        {{ t("actions.backToHome").toUpperCase() }}
      </Btn>
    </template>
  </Box>
</template>
