<template>
  <Disclosure :default-open="visible">
    <DisclosurePanel class="panel-details">
      <slot />
    </DisclosurePanel>
  </Disclosure>
</template>

<script lang="ts" setup>
import { Disclosure, DisclosureButton, DisclosurePanel } from "@headlessui/vue";

type Props = {
  visible: boolean;
};

withDefaults(defineProps<Props>(), {
  visible: false,
});
</script>

<script lang="ts">
export default {
  name: "PanelDetails",
};
</script>
