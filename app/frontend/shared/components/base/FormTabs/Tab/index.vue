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

/**
 * Held by content, not identity. A template passes `:fields="['name']"` as a
 * fresh array on every render of the slot, and FormTabs renders that slot: each
 * new array re-rendered the strip, which rendered the slot again, until Vue gave
 * up with "Maximum recursive updates exceeded".
 */
const fields = computed<string[]>((previous) =>
  previous &&
  previous.length === props.fields.length &&
  previous.every((field, index) => field === props.fields[index])
    ? previous
    : props.fields,
);

context.registerTab({
  id: props.id,
  label: toRef(props, "label"),
  fields,
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
