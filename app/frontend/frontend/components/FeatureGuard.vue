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
import { PanelTonesEnum } from "@/shared/components/base/Panel/types";
import { HeadingSizeEnum } from "@/shared/components/base/Heading/types";
import type { FeatureFlagName, Fleet } from "@/services/fyApi";

type Props = {
  feature: FeatureFlagName;
  // Pass the fleet for a flag a fleet can be gated on, so the answer is about
  // this fleet and not about every fleet the viewer belongs to.
  fleet?: Fleet;
};

const props = defineProps<Props>();

const { t } = useI18n();
const { isFeatureEnabled, isFleetFeatureEnabled } = useFeatures();

const enabled = computed(() =>
  props.fleet
    ? isFleetFeatureEnabled(props.fleet, props.feature)
    : isFeatureEnabled(props.feature),
);
</script>

<template>
  <slot v-if="enabled"></slot>
  <Box
    v-else
    :tone="PanelTonesEnum.PRIMARY"
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
      <Btn :to="{ name: 'home' }">
        <i class="fa fa-chevron-left" />
        {{ t("actions.backToHome").toUpperCase() }}
      </Btn>
    </template>
  </Box>
</template>
