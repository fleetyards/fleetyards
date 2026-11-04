<script lang="ts">
export default {
  name: "SupportBtn",
};
</script>

<script lang="ts" setup>
import Btn from "@/shared/components/base/Btn/index.vue";
import {
  BtnSizesEnum,
  BtnVariantsEnum,
} from "@/shared/components/base/Btn/types";

import { useI18n } from "@/shared/composables/useI18n";

interface Props {
  size?: `${BtnSizesEnum}`;
  variant?: `${BtnVariantsEnum}`;
}

withDefaults(defineProps<Props>(), {
  size: undefined,
  variant: undefined,
});

const { t } = useI18n();
</script>

<template>
  <!-- Slotted so the footer can keep its own label and heart; the default is
       what every other caller shows. -->
  <Btn
    class="support-button"
    :size="size"
    :variant="variant"
    :to="{ name: 'support' }"
  >
    <slot>{{ t("actions.supportUs") }}</slot>
  </Btn>
</template>
