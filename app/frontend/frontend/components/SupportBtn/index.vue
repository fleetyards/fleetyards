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

import { useSupportModal } from "@/frontend/composables/useSupportModal";
import { useI18n } from "@/shared/composables/useI18n";

type Props = {
  size?: `${BtnSizesEnum}`;
  variant?: `${BtnVariantsEnum}`;
};

withDefaults(defineProps<Props>(), {
  size: undefined,
  variant: undefined,
});

const { t } = useI18n();

const { openSupportModal } = useSupportModal();
</script>

<template>
  <!-- Slotted so the footer can keep its own label and heart without a second
       copy of the modal-opening logic; the default is what every other caller
       already showed. -->
  <Btn
    class="support-button"
    :size="size"
    :variant="variant"
    @click="openSupportModal"
  >
    <slot>{{ t("actions.supportUs") }}</slot>
  </Btn>
</template>
