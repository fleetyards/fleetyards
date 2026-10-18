<script lang="ts">
export default {
  name: "HangarSyncNumberText",
};
</script>

<script lang="ts" setup>
import NumberFlow from "@number-flow/vue";
import { useI18n } from "@/shared/composables/useI18n";
import type { SyncNumberTextValue } from "./types";

type Props = {
  text: SyncNumberTextValue;
};

const props = defineProps<Props>();

const { t } = useI18n();

const PLACEHOLDER = /%\{(\w+)\}/g;

// Each value passed as its own placeholder, so the translation keeps it where
// the language puts it.
const template = computed(() => {
  if (props.text.template) return props.text.template;

  const standing = Object.fromEntries(
    Object.keys(props.text.values).map((name) => [name, `%{${name}}`]),
  );

  return t(props.text.key ?? "", standing);
});

const parts = computed(() =>
  template.value
    .split(PLACEHOLDER)
    .map((part, index) =>
      index % 2 === 1 && part in props.text.values
        ? { number: props.text.values[part] }
        : { text: part },
    )
    .filter((part) => "number" in part || part.text),
);

// The line as plain text, for screen readers and for tests: an animated
// number reads its digits out of order.
const plain = computed(() =>
  template.value.replace(PLACEHOLDER, (match, name: string) =>
    name in props.text.values ? String(props.text.values[name]) : match,
  ),
);
</script>

<template>
  <span class="sync-number-text" :data-text="plain">
    <span class="sr-only">{{ plain }}</span>
    <span aria-hidden="true">
      <template v-for="(part, index) in parts" :key="index">
        <NumberFlow
          v-if="'number' in part"
          class="sync-number-text__number"
          :value="part.number ?? 0"
        />
        <template v-else>{{ part.text }}</template>
      </template>
    </span>
  </span>
</template>

<style lang="scss" scoped>
.sync-number-text {
  font-variant-numeric: tabular-nums;
}
</style>
