<script lang="ts">
export default {
  name: "InviteInvalid",
};
</script>

<script lang="ts" setup>
import Btn from "@/shared/components/base/Btn/index.vue";
import Box from "@/shared/components/Box/index.vue";
import Text from "@/shared/components/base/Text/index.vue";
import { useI18n } from "@/shared/composables/useI18n";
import { PanelTonesEnum } from "@/shared/components/base/Panel/types";
import { HeadingSizeEnum } from "@/shared/components/base/Heading/types";

type Props = {
  token?: string;
};

defineProps<Props>();

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
      {{ t("headlines.inviteInvalid") }}
    </template>
    <template #default>
      <Text>{{ t("texts.inviteInvalid") }}</Text>
      <Text v-if="token" muted no-spacing>
        {{ t("labels.inviteToken") }}:
        <span class="invite-invalid__token">{{ token }}</span>
      </Text>
    </template>
    <template #footer>
      <Btn :to="{ name: 'home' }">
        <i class="fa fa-chevron-left" />
        {{ t("actions.backToHome").toUpperCase() }}
      </Btn>
    </template>
  </Box>
</template>

<style lang="scss" scoped>
.invite-invalid__token {
  padding: 0.1rem 0.35rem;
  font-family: monospace;
  font-size: 0.85rem;
  background: rgba(255, 255, 255, 0.04);
  border-radius: 3px;
  // A token is opaque and arbitrarily long, so it breaks anywhere rather than
  // running out of the box.
  overflow-wrap: anywhere;
}
</style>
