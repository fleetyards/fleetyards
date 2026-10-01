<script lang="ts">
export default {
  name: "FormMarkdownEditorCatalogueSuggestionList",
};
</script>

<script lang="ts" setup>
import { type CatalogueTokenMatch } from "@/services/fyApi";
import { useI18n } from "@/shared/composables/useI18n";

type Props = {
  items: CatalogueTokenMatch[];
  query: string;
  command: (item: CatalogueTokenMatch) => void;
};

const props = defineProps<Props>();

const { t } = useI18n();

const selected = ref(0);

watch(
  () => props.items,
  () => {
    selected.value = 0;
  },
);

const choose = (index: number) => {
  const item = props.items[index];

  if (item) props.command(item);
};

// Called by the editor while the list is open: the text keeps focus, so the
// list is driven from its keys rather than by moving focus into it.
const onKeyDown = (event: KeyboardEvent) => {
  if (!props.items.length) return false;

  if (event.key === "ArrowDown") {
    selected.value = (selected.value + 1) % props.items.length;
    return true;
  }

  if (event.key === "ArrowUp") {
    selected.value =
      (selected.value - 1 + props.items.length) % props.items.length;
    return true;
  }

  if (event.key === "Enter" || event.key === "Tab") {
    choose(selected.value);
    return true;
  }

  return false;
};

defineExpose({ onKeyDown });
</script>

<template>
  <div
    class="catalogue-suggestions"
    data-test="markdown-editor-item-suggestions"
  >
    <ul
      v-if="items.length"
      role="listbox"
      :aria-label="t('markdownEditor.item')"
    >
      <li
        v-for="(item, index) in items"
        :key="`${item.type}-${item.slug}`"
        role="option"
        :aria-selected="index === selected"
        class="catalogue-suggestions__item"
        :class="{ 'catalogue-suggestions__item--selected': index === selected }"
        :data-test="`markdown-editor-item-suggestion-${item.slug}`"
        @mousedown.prevent
        @mouseenter="selected = index"
        @click="choose(index)"
      >
        <span class="catalogue-suggestions__name">{{ item.name }}</span>
        <span class="catalogue-suggestions__type">
          {{ t(`markdownEditor.itemType.${item.type}`) }}
        </span>
      </li>
    </ul>
    <p v-else class="catalogue-suggestions__hint">
      {{
        query.trim().length < 2
          ? t("markdownEditor.itemSearchHint")
          : t("markdownEditor.itemSearchEmpty")
      }}
    </p>
  </div>
</template>

<style lang="scss" scoped>
.catalogue-suggestions {
  z-index: 2100;
  min-width: 240px;
  max-width: min(420px, calc(100vw - 16px));
  max-height: 280px;
  overflow-y: auto;
  padding: 4px;
  background-color: var(--color-field, rgb(18 20 23 / 0.96));
  border: 1px solid var(--color-edge-soft, rgb(122 130 136 / 0.28));
  border-radius: var(--radius-control, 8px);
  box-shadow: 0 4px 12px rgb(0 0 0 / 0.4);

  ul {
    margin: 0;
    padding: 0;
    list-style: none;
  }
}

.catalogue-suggestions__item {
  display: flex;
  align-items: baseline;
  justify-content: space-between;
  gap: 12px;
  padding: 6px 8px;
  border-radius: var(--radius-control-inner, 7px);
  cursor: pointer;

  &--selected {
    background-color: var(--color-control-hover, rgb(52 58 64 / 0.95));
  }
}

.catalogue-suggestions__type,
.catalogue-suggestions__hint {
  color: var(--color-text-dim, #959595);
  font-size: 0.8rem;
}

.catalogue-suggestions__hint {
  margin: 0;
  padding: 6px 8px;
}
</style>
