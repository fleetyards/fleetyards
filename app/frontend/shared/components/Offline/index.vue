<script lang="ts">
export default {
  name: "Offline",
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
  retry?: () => void;
};

const props = withDefaults(defineProps<Props>(), {
  retry: undefined,
});

const { t } = useI18n();

const retry = () => props.retry?.();

// This screen is rendered from an error that has already settled, so the
// connection coming back moves nothing on its own — the same retry the button
// offers runs as soon as the device is back, rather than waiting to be pressed.
onMounted(() => {
  window.addEventListener("online", retry);
});

onBeforeUnmount(() => {
  window.removeEventListener("online", retry);
});
</script>

<template>
  <Box
    :tone="PanelTonesEnum.ERROR"
    :heading-size="HeadingSizeEnum.HERO"
    animated
    large
  >
    <template #heading>
      {{ t("headlines.offline") }}
    </template>
    <template #default>
      <Text>{{ t("texts.offline") }}</Text>
    </template>
    <template v-if="props.retry" #footer>
      <Btn @click="retry">
        <i class="fa-duotone fa-rotate" />
        {{ t("actions.retry").toUpperCase() }}
      </Btn>
    </template>
  </Box>
</template>
