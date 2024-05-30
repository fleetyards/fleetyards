<script lang="ts">
export default {
  name: "NavFooter",
};
</script>

<script lang="ts" setup>
import NavItem from "../NavItem/index.vue";
import { useMobile } from "@/shared/composables/useMobile";
import { useI18n } from "@/shared/composables/useI18n";
import { useNavStore } from "@/shared/stores/nav";

const { t } = useI18n();

const mobile = useMobile();

const navStore = useNavStore();

const slim = computed(() => {
  return navStore.slim && !mobile.value;
});

const toggleSlimLabel = computed(() => {
  if (slim.value) {
    return t("nav.toggleSlimExpand");
  }

  return t("nav.toggleSlimCollapse");
});

const toggleSlim = () => {
  navStore.toggleSlim();
};
</script>

<template>
  <ul class="nav-bottom">
    <NavItem
      v-if="!mobile"
      :action="toggleSlim"
      :label="toggleSlimLabel"
      :icon="
        slim ? 'fal fa-chevron-double-right' : 'fal fa-chevron-double-left'
      "
    />
    <slot />
  </ul>
</template>
