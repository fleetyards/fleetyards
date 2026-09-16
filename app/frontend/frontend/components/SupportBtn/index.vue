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
  /**
   * Go to the support page instead of opening the modal. The home page does:
   * it is an entry point, and a modal over it is a detour where a page of its
   * own can be linked to and shared.
   */
  page?: boolean;
};

const props = withDefaults(defineProps<Props>(), {
  size: undefined,
  variant: undefined,
  page: false,
});

const { t } = useI18n();

const { openModal } = useModalQuery();

const supportPage = computed(() =>
  props.page ? { name: "support" } : undefined,
);

// The address is what opens it, and writing to the address is a navigation --
// nothing here waits for it.
const openSupport = () => {
  if (props.page) return;

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
    :to="supportPage"
    @click="openSupport"
  >
    <slot>{{ t("actions.supportUs") }}</slot>
  </Btn>
</template>
