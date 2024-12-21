<script lang="ts">
export default {
  name: "CheckAccess",
};
</script>

<script lang="ts" setup>
import { PanelVariantsEnum } from "@/shared/components/Panel/types";
import { HeadingLevelEnum } from "@/shared/components/base/Heading/types";
import { useI18n } from "@/shared/composables/useI18n";

type Props = {
  check: (resource?: string) => boolean;
  resource?: string;
};

const props = withDefaults(defineProps<Props>(), {
  resource: undefined,
});

const { t } = useI18n();

const granted = ref<boolean>();

onMounted(() => {
  if (!props.resource || props.resource === "all") {
    granted.value = true;
    return;
  }

  granted.value = props.check(props.resource);
});

watch(
  () => props.resource,
  () => {
    granted.value = props.check(props.resource);
  },
);
</script>

<template>
  <slot v-if="granted" name="granted"></slot>
  <Box v-else :variant="PanelVariantsEnum.ERROR" large>
    <Heading :level="HeadingLevelEnum.H1">{{
      t("headlines.accessDenied")
    }}</Heading>
    <Text>{{ t("texts.accessDenied") }}</Text>
    <template #footer>
      <Btn :to="{ name: 'home' }" :exact="true">
        <i class="fa fa-chevron-left" />
        {{ t("actions.backToHome").toUpperCase() }}
      </Btn>
    </template>
  </Box>
</template>
