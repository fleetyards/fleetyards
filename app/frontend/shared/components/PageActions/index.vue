<script lang="ts">
export default {
  name: "PageActions",
};
</script>

<script lang="ts" setup>
import BtnDropdown from "@/shared/components/base/BtnDropdown/index.vue";
import { BTN_CONTAINER } from "@/shared/components/base/Btn/context";
import { BtnSizesEnum } from "@/shared/components/base/Btn/types";
import { useMobile } from "@/shared/composables/useMobile";

type Props = {
  // A selection takes the header over on a phone, and the actions go with
  // the search: nothing is left in the slot to claim the header's gap.
  hidden?: boolean;
};

withDefaults(defineProps<Props>(), {
  hidden: false,
});

const mobile = useMobile();

// The buttons are written once, without a size, and take the header's. In
// the phone's menu the menu's own context is the nearer one and wins.
provide(BTN_CONTAINER, {
  container: "header",
  size: computed(() => BtnSizesEnum.MD),
  block: computed(() => false),
});
</script>

<template>
  <!-- A page's actions, as buttons in the header beside the search. On a
       phone they would take a row of their own under it, so they fold into
       one menu instead and the header stays a single row. -->
  <Teleport to="#header-right">
    <template v-if="!hidden">
      <BtnDropdown
        v-if="mobile"
        class="navigation-header-pinned"
        expand-left
        data-test="page-actions-menu"
      >
        <slot />
      </BtnDropdown>
      <slot v-else />
    </template>
  </Teleport>
</template>
