<script lang="ts">
export default {
  name: "FormTab",
};
</script>

<script lang="ts" setup>
import { toRef } from "vue";
import { formTabsContextKey } from "@/shared/components/base/FormTabs/types";

type Props = {
  id: string;
  label: string;
  fields?: string[];
  disabled?: boolean;
  hidden?: boolean;
  icon?: string;
  iconSrc?: string;
  hint?: string;
};

const props = withDefaults(defineProps<Props>(), {
  fields: () => [],
  disabled: false,
  hidden: false,
  icon: undefined,
  iconSrc: undefined,
  hint: undefined,
});

const context = inject(formTabsContextKey, null);

if (!context) {
  throw new Error("FormTab must be used inside <FormTabs>");
}

context.registerTab({
  id: props.id,
  label: toRef(props, "label"),
  fields: toRef(props, "fields"),
  disabled: toRef(props, "disabled"),
  hidden: toRef(props, "hidden"),
  icon: toRef(props, "icon"),
  iconSrc: toRef(props, "iconSrc"),
  hint: toRef(props, "hint"),
});

onUnmounted(() => {
  context.unregisterTab(props.id);
});

const isActive = computed(() => context.isActive(props.id));
</script>

<template>
  <div
    v-show="isActive && !hidden"
    :id="`form-tab-panel-${id}`"
    role="tabpanel"
    :aria-labelledby="`form-tab-${id}`"
    class="form-tab"
  >
    <slot />
  </div>
</template>
