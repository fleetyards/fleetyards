<script lang="ts">
export default {
  name: "HangarPlannerPickList",
};
</script>

<script lang="ts" setup>
import Btn from "@/shared/components/base/Btn/index.vue";
import {
  BtnSizesEnum,
  BtnVariantsEnum,
} from "@/shared/components/base/Btn/types";
import FormInput from "@/shared/components/base/FormInput/index.vue";
import ListToolbar from "@/shared/components/base/ListToolbar/index.vue";
import Pill from "@/shared/components/base/Pill/index.vue";
import RowsSkeleton from "@/shared/components/RowsSkeleton/index.vue";
import { PillVariantsEnum } from "@/shared/components/base/Pill/types";
import type { BaseTableCol } from "@/shared/components/base/Table/types";
import { useI18n } from "@/shared/composables/useI18n";

export type PickListItem = {
  id: string;
  title: string;
  meta?: string;
  price?: string;
  badge?: string;
  // Text the search matches beyond the title, such as the ships a pledge holds.
  keywords?: string;
  // What the price sort orders by; an unknown price sorts last either way.
  sortPrice?: number | null;
  // Held above the rest whatever the sort: the exact match the list is for.
  pinned?: boolean;
};

type Props = {
  name: string;
  items: PickListItem[];
  // Selected item in select mode; leave unset for a list of actions.
  modelValue?: string | null;
  // Shown on each row's button in action mode.
  actionLabel?: string;
  empty: string;
  loading?: boolean;
  // Opens on the full list even with a pick made, for a list the user asked to
  // change.
  startOpen?: boolean;
  // The pick reads as one line at a field's height, for a list that stands in
  // a row beside other fields.
  compact?: boolean;
};

const props = withDefaults(defineProps<Props>(), {
  modelValue: undefined,
  actionLabel: undefined,
  loading: false,
  startOpen: false,
  compact: false,
});

const emit = defineEmits<{
  "update:modelValue": [value: string];
  pick: [item: PickListItem];
}>();

const { t } = useI18n();

const SEARCH_FROM = 6;
const DEFAULT_SORT = "price asc";

const search = ref("");

// What the sort bar picked; undefined is the default. Kept here rather than in
// the URL, which belongs to the page under the modal.
const sort = ref<string>();

const sortColumns = computed<BaseTableCol<PickListItem>[]>(() => [
  {
    name: "price",
    label: t("hangarPlanner.route.sort.price"),
    sortable: true,
  },
  {
    name: "title",
    label: t("hangarPlanner.route.sort.name"),
    sortable: true,
  },
]);

const priced = computed(() =>
  props.items.some((item) => typeof item.sortPrice === "number"),
);

const visible = computed(() => {
  const query = search.value.trim().toLowerCase();
  if (!query) return props.items;

  return props.items.filter((item) =>
    [item.title, item.meta, item.keywords]
      .filter(Boolean)
      .join(" ")
      .toLowerCase()
      .includes(query),
  );
});

const sorted = computed(() => {
  const [key, direction] = (sort.value || DEFAULT_SORT).split(" ");
  const sign = direction === "desc" ? -1 : 1;

  return [...visible.value].sort((a, b) => {
    if (!!a.pinned !== !!b.pinned) return a.pinned ? -1 : 1;
    if (key === "title") return sign * a.title.localeCompare(b.title);

    const left = a.sortPrice;
    const right = b.sortPrice;
    // An item without a price sorts last either way round.
    if (typeof left !== "number" && typeof right !== "number") {
      return a.title.localeCompare(b.title);
    }
    if (typeof left !== "number") return 1;
    if (typeof right !== "number") return -1;

    return sign * (left - right) || a.title.localeCompare(b.title);
  });
});

const selectable = computed(() => props.actionLabel === undefined);

// Once picked, the list folds to the pick, the way a filled field reads; the
// full list comes back only when asked for.
const expanded = ref(props.startOpen);

const chosen = computed(() =>
  selectable.value && !expanded.value
    ? props.items.find((item) => item.id === props.modelValue)
    : undefined,
);

const choose = (item: PickListItem) => {
  if (selectable.value) {
    emit("update:modelValue", item.id);
    expanded.value = false;
    search.value = "";
  }
  emit("pick", item);
};
</script>

<template>
  <div class="pick-list">
    <RowsSkeleton
      v-if="loading"
      :count="3"
      trailing
      data-test="pick-list-loading"
    />
    <div
      v-else-if="chosen"
      class="pick-list__row pick-list__row--selected"
      :class="{ 'pick-list__row--compact': compact }"
      :data-test="`pick-list-chosen-${name}`"
    >
      <span class="pick-list__text">
        <span class="pick-list__title">{{ chosen.title }}</span>
        <span v-if="chosen.meta" class="pick-list__meta">{{
          chosen.meta
        }}</span>
      </span>
      <span v-if="chosen.price" class="pick-list__price">{{
        chosen.price
      }}</span>
      <Btn
        :size="BtnSizesEnum.XS"
        :variant="BtnVariantsEnum.GHOST"
        data-test="pick-list-change"
        @click="expanded = true"
      >
        {{ t("hangarPlanner.route.change") }}
      </Btn>
    </div>
    <template v-else>
      <slot name="filters" />
      <FormInput
        v-if="items.length >= SEARCH_FROM"
        v-model="search"
        :name="`${name}-search`"
        :label="t('hangarPlanner.route.search')"
        icon="fa-light fa-magnifying-glass"
        no-label
        :placeholder="t('hangarPlanner.route.search')"
        standalone
      />
      <ListToolbar
        v-if="priced && items.length > 1"
        v-model:sort="sort"
        class="pick-list__sort"
        :columns="sortColumns"
        :default-sort="DEFAULT_SORT"
        :data-test="`pick-list-sort-${name}`"
        local
      />
      <p v-if="!items.length" class="pick-list__empty">{{ empty }}</p>
      <p v-else-if="!visible.length" class="pick-list__empty">
        {{ t("hangarPlanner.route.noMatch") }}
      </p>
      <ul v-else class="pick-list__rows" :data-test="`pick-list-${name}`">
        <li v-for="item in sorted" :key="item.id">
          <component
            :is="selectable ? 'button' : 'div'"
            :type="selectable ? 'button' : undefined"
            class="pick-list__row"
            :class="{
              'pick-list__row--selected': selectable && modelValue === item.id,
              'pick-list__row--button': selectable,
            }"
            :aria-pressed="selectable ? modelValue === item.id : undefined"
            data-test="pick-list-row"
            @click="selectable && choose(item)"
          >
            <span class="pick-list__text">
              <span class="pick-list__title">{{ item.title }}</span>
              <span v-if="item.meta" class="pick-list__meta">{{
                item.meta
              }}</span>
              <Pill
                v-if="item.badge"
                :variant="PillVariantsEnum.DEFAULT"
                class="pick-list__badge"
              >
                {{ item.badge }}
              </Pill>
            </span>
            <span v-if="item.price" class="pick-list__price">{{
              item.price
            }}</span>
            <i
              v-if="selectable && modelValue === item.id"
              class="fa-solid fa-check pick-list__check"
              aria-hidden="true"
            />
            <Btn
              v-if="!selectable"
              :size="BtnSizesEnum.XS"
              data-test="pick-list-use"
              @click="choose(item)"
            >
              {{ actionLabel }}
            </Btn>
          </component>
        </li>
      </ul>
    </template>
  </div>
</template>

<style lang="scss" scoped>
.pick-list {
  display: flex;
  flex-direction: column;
  gap: 8px;
}

.pick-list__sort {
  align-self: flex-start;
}

.pick-list__empty {
  margin: 0;
  color: var(--color-text-dim);
}

.pick-list__rows {
  display: flex;
  flex-direction: column;
  gap: 6px;
  max-height: 320px;
  margin: 0;
  padding: 0;
  overflow-y: auto;
  list-style: none;
}

.pick-list__row {
  display: flex;
  gap: 12px;
  align-items: center;
  width: 100%;
  min-height: 48px;
  padding: 8px 12px;
  border: 1px solid var(--color-edge-soft);
  border-radius: 8px;
  background: var(--color-control);
  color: var(--color-text);
  font: inherit;
  text-align: left;
}

.pick-list__row--button {
  cursor: pointer;

  &:hover {
    background: var(--color-control-hover);
  }

  &:focus-visible {
    outline: 2px solid var(--color-primary);
    outline-offset: 1px;
  }
}

.pick-list__row--selected {
  border-color: var(--color-primary);
}

.pick-list__text {
  display: flex;
  flex: 1;
  flex-direction: column;
  gap: 2px;
  min-width: 0;
}

.pick-list__title {
  font-weight: 600;
  color: var(--color-lifted);
}

.pick-list__meta {
  font-size: 0.8rem;
  color: var(--color-text-dim);
}

.pick-list__badge {
  align-self: flex-start;
  max-width: 100%;
  margin-top: 4px;
  overflow: hidden;
  text-overflow: ellipsis;
}

// A field's height, with the name and its detail on one line.
.pick-list__row--compact {
  min-height: 43px;
  padding: 4px 6px 4px 14px;

  .pick-list__text {
    flex-direction: row;
    gap: 8px;
    align-items: baseline;
    overflow: hidden;
    white-space: nowrap;
  }

  .pick-list__title,
  .pick-list__meta {
    overflow: hidden;
    text-overflow: ellipsis;
  }
}

.pick-list__price {
  font-weight: 600;
  white-space: nowrap;
}

.pick-list__check {
  color: var(--color-primary);
}
</style>
