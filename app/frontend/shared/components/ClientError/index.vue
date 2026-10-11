<script lang="ts">
export default {
  name: "ClientError",
};
</script>

<script lang="ts" setup>
import Btn from "@/shared/components/base/Btn/index.vue";
import Box from "@/shared/components/Box/index.vue";
import Text from "@/shared/components/base/Text/index.vue";
import { HeadingSizeEnum } from "@/shared/components/base/Heading/types";
import { useI18n } from "@/shared/composables/useI18n";
import { PanelTonesEnum } from "@/shared/components/base/Panel/types";

interface Props {
  reset?: () => void;
}

const props = withDefaults(defineProps<Props>(), {
  reset: undefined,
});

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
      {{ t("headlines.invalidRequest") }}
    </template>
    <template #default>
      <Text v-if="props.reset">{{ t("texts.invalidListRequest") }}</Text>
      <Text v-else>{{ t("texts.invalidRequest") }}</Text>
    </template>
    <template v-if="props.reset" #footer>
      <Btn data-test="client-error-reset" @click="props.reset">
        <i class="fa-light fa-times" />
        {{ t("actions.resetFilter").toUpperCase() }}
      </Btn>
    </template>
  </Box>
</template>
