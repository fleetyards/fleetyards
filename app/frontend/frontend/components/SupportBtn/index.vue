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

import { useModalQuery } from "@/frontend/composables/useModalQuery";
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

const { openModal } = useModalQuery();

// The address is what opens it, and writing to the address is a navigation --
// nothing here waits for it.
const openSupport = () => {
  void openModal("support");
};
</script>

<template>
  <!-- Slotted so the footer can keep its own label and heart without a second
       copy of the modal-opening logic; the default is what every other caller
       already showed. -->
  <Btn
    class="support-button"
    :size="size"
    :variant="variant"
    @click="openSupport"
  >
    <slot>{{ t("actions.supportUs") }}</slot>
  </Btn>
</template>
