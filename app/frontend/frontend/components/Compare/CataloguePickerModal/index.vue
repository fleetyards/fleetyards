<script lang="ts">
export default {
  name: "CompareCataloguePickerModal",
};
</script>

<script lang="ts" setup>
import Modal from "@/shared/components/AppModal/Inner/index.vue";
import Btn from "@/shared/components/base/Btn/index.vue";
import { BtnVariantsEnum } from "@/shared/components/base/Btn/types";
import Chip from "@/shared/components/base/Chip/index.vue";
import { ChipStatesEnum } from "@/shared/components/base/Chip/types";
import CataloguePicker, {
  type CatalogueItem,
} from "@/frontend/components/CataloguePicker/index.vue";
import { MAX_MODELS } from "@/frontend/components/Compare/constants";
import {
  componentCompareCategory,
  equipmentCompareCategory,
  type CompareCategory,
} from "@/frontend/components/Compare/category";
import { useCompareSet } from "@/frontend/composables/useCompareSet";
import { useComponentCategoryLabel } from "@/frontend/composables/useComponentCategoryLabel";
import { useComlink } from "@/shared/composables/useComlink";
import { useI18n } from "@/shared/composables/useI18n";
import {
  type Component,
  type ComponentQuery,
  type Equipment,
  type EquipmentQuery,
} from "@/services/fyApi";

type Props = {
  kind: "Component" | "Equipment";
  queryKey: string;
  // The category the set already holds. Absent for an empty set, whose first
  // pick decides it.
  lock?: CompareCategory<ComponentQuery | EquipmentQuery>;
};

const props = withDefaults(defineProps<Props>(), {
  lock: undefined,
});

const { t } = useI18n();

const comlink = useComlink();

const categoryLabel = useComponentCategoryLabel();

const { slugs: compared, replace, flush } = useCompareSet(props.queryKey);

// Read once, at open: the picker adds to the set the page had when it opened.
const taken = new Set(compared.value);

const selection = ref<CatalogueItem[]>([]);

const categoryOf = (item: CatalogueItem) =>
  props.kind === "Component"
    ? componentCompareCategory(item as Component, categoryLabel)
    : equipmentCompareCategory(item as Equipment);

// The set's category, or the first pick's when the set is empty: a comparison
// holds one category, so the rest of the catalogue goes out of reach with it.
// Only the set's narrows the query; a pick's greys the other cards out instead,
// so picking or dropping the first one does not reload the grid under the
// reader.
const lock = computed(
  () =>
    props.lock ??
    (selection.value[0] ? categoryOf(selection.value[0]) : undefined),
);

const selectedIds = computed(
  () => new Set(selection.value.map((item) => item.id)),
);

const atMax = computed(() => taken.size + selection.value.length >= MAX_MODELS);

const isSelected = (item: CatalogueItem) => selectedIds.value.has(item.id);

const cardDisabled = (item: CatalogueItem) => {
  if (selectedIds.value.has(item.id)) return false;
  if (taken.has(item.slug) || atMax.value) return true;

  return !!lock.value && categoryOf(item)?.key !== lock.value.key;
};

const toggle = (item: CatalogueItem) => {
  if (selectedIds.value.has(item.id)) {
    selection.value = selection.value.filter((entry) => entry.id !== item.id);
    return;
  }

  if (cardDisabled(item)) return;

  selection.value = [...selection.value, item];
};

const remove = (id: string) => {
  selection.value = selection.value.filter((entry) => entry.id !== id);
};

const badgesOf = (item: CatalogueItem) =>
  taken.has(item.slug)
    ? [
        {
          key: "comparing",
          label: t("modelPicker.badges.comparing"),
          primary: true,
        },
      ]
    : [];

const save = () => {
  replace([...taken, ...selection.value.map((item) => item.slug)]);
  // The write is debounced and would be dropped as the modal unmounts.
  flush();

  comlink.emit("close-modal", true);
};

const title = computed(() =>
  props.kind === "Component"
    ? t("labels.compare.selectComponents")
    : t("labels.compare.selectEquipment"),
);
</script>

<template>
  <Modal :title="title" flush>
    <CataloguePicker
      :kind="kind"
      :query="props.lock?.query"
      :hide-filter="!!lock"
      :is-selected="isSelected"
      :is-disabled="cardDisabled"
      :badges-of="badgesOf"
      card-test-prefix="compare-picker-card"
      @toggle="toggle"
    >
      <template #summary>
        <span v-if="lock" class="compare-picker__lock">
          {{ t("labels.compare.onlyCategory", { category: lock.label }) }}
        </span>
        <span v-if="atMax" class="compare-picker__hint">
          {{ t("labels.compare.enoughItems") }}
        </span>
      </template>
      <template v-if="selection.length" #tray>
        <Chip
          v-for="item in selection"
          :key="item.id"
          :state="ChipStatesEnum.INCLUDED"
          @toggle="remove(item.id)"
        >
          {{ item.name }}
        </Chip>
      </template>
    </CataloguePicker>

    <template #footer-start>
      <span class="compare-picker__selected">
        {{ t("modelPicker.labels.selected", { count: selection.length }) }}
      </span>
    </template>
    <template #footer>
      <Btn
        v-if="selection.length"
        :variant="BtnVariantsEnum.GHOST"
        @click="selection = []"
      >
        {{ t("modelPicker.actions.clearSelection") }}
      </Btn>
      <Btn
        :disabled="!selection.length"
        data-test="compare-picker-submit"
        @click="save"
      >
        {{ t("actions.compare.item") }}
      </Btn>
    </template>
  </Modal>
</template>

<style scoped>
@reference "../../../../entrypoints/tailwind.css";

.compare-picker__lock {
  @apply text-muted text-[13px];
  font-variant-numeric: tabular-nums;
}

.compare-picker__hint {
  @apply text-gold text-[13px];
}

.compare-picker__selected {
  @apply text-[15px];
  font-variant-numeric: tabular-nums;
}
</style>
