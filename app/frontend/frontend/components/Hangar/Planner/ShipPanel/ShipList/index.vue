<script lang="ts">
export default {
  name: "HangarPlannerShipList",
};
</script>

<script lang="ts" setup>
import { useElementSize } from "@vueuse/core";
import Btn from "@/shared/components/base/Btn/index.vue";
import BtnGroup from "@/shared/components/base/BtnGroup/index.vue";
import { BtnSizesEnum } from "@/shared/components/base/Btn/types";
import Chip from "@/shared/components/base/Chip/index.vue";
import { ChipStatesEnum } from "@/shared/components/base/Chip/types";
import FormInput from "@/shared/components/base/FormInput/index.vue";
import Pill from "@/shared/components/base/Pill/index.vue";
import { PillVariantsEnum } from "@/shared/components/base/Pill/types";
import RowsSkeleton from "@/shared/components/RowsSkeleton/index.vue";
import ShipName from "@/frontend/components/Hangar/Planner/ShipName/index.vue";
import type {
  ShipListItem,
  ShipListSection,
} from "@/frontend/components/Hangar/Planner/ShipPanel/ShipList/types";
import { useI18n } from "@/shared/composables/useI18n";

type Props = {
  name: string;
  sections: ShipListSection[];
  items: ShipListItem[];
  // What the price column holds, which the price sort is named after.
  priceLabel: string;
  empty: string;
  loading?: boolean;
  modelValue?: string;
};

const props = withDefaults(defineProps<Props>(), {
  loading: false,
  modelValue: undefined,
});

const emit = defineEmits<{
  "update:modelValue": [id: string];
  commit: [item: ShipListItem];
}>();

defineSlots<{
  detail(props: { item: ShipListItem }): unknown;
  "detail-empty"(): unknown;
}>();

const { t } = useI18n();

const root = useTemplateRef<HTMLElement>("root");
const { width } = useElementSize(root);

// Too narrow for the detail beside the list, it opens under its row instead.
const inline = computed(() => width.value > 0 && width.value < 640);

const search = ref("");
const sort = ref<"price" | "name">("price");
const picked = ref<string[]>([]);

const matches = (item: ShipListItem, query: string) =>
  [
    item.title,
    item.meta,
    item.ship?.manufacturerName,
    ...(item.tags ?? []).map((tag) => tag.label),
    item.keywords,
  ]
    .filter(Boolean)
    .join(" ")
    .toLowerCase()
    .includes(query);

const searched = computed(() => {
  const query = search.value.trim().toLowerCase();

  return query
    ? props.items.filter((item) => matches(item, query))
    : props.items;
});

const byOrder = (a: ShipListItem, b: ShipListItem) => {
  if (!!a.pinned !== !!b.pinned) return a.pinned ? -1 : 1;
  if (sort.value === "name") return a.title.localeCompare(b.title);

  const left = a.sortPrice;
  const right = b.sortPrice;
  // An item without a price sorts last.
  if (typeof left !== "number" && typeof right !== "number") {
    return a.title.localeCompare(b.title);
  }
  if (typeof left !== "number") return 1;
  if (typeof right !== "number") return -1;

  return left - right || a.title.localeCompare(b.title);
};

const countOf = (section: string) =>
  searched.value.filter((item) => item.section === section).length;

const shownSections = computed(() =>
  props.sections
    .filter((section) => countOf(section.key) > 0)
    .filter(
      (section) => !picked.value.length || picked.value.includes(section.key),
    )
    .map((section) => ({
      ...section,
      items: searched.value
        .filter((item) => item.section === section.key)
        .sort(byOrder),
    })),
);

// Sections to narrow to, offered only where there is more than one to tell
// apart.
const chips = computed(() =>
  props.sections.filter((section) =>
    props.items.some((item) => item.section === section.key),
  ),
);

const toggle = (section: string) => {
  picked.value = picked.value.includes(section)
    ? picked.value.filter((entry) => entry !== section)
    : [...picked.value, section];
};

const pickable = computed(() =>
  shownSections.value.flatMap((section) =>
    section.items.filter((item) => !item.reason),
  ),
);

const selected = computed(() =>
  props.items.find((item) => item.id === props.modelValue && !item.reason),
);

const select = (item: ShipListItem) => {
  if (item.reason) return;
  emit("update:modelValue", item.id);
};

// Beside the list the pane is never empty, so the first ship is shown until
// another is picked.
watch(
  [pickable, inline],
  () => {
    if (inline.value || selected.value || !pickable.value.length) return;
    select(pickable.value[0]);
  },
  { immediate: true },
);

const rows = useTemplateRef<HTMLButtonElement[]>("rows");

const focusRow = (id: string) => {
  void nextTick(() => {
    rows.value
      ?.find((row) => row.dataset.id === id)
      ?.focus({ preventScroll: false });
  });
};

const move = (step: number) => {
  const list = pickable.value;
  if (!list.length) return;

  const index = list.findIndex((item) => item.id === props.modelValue);
  const next =
    list[Math.min(Math.max(index + step, 0), list.length - 1)] ?? list[0];

  select(next);
  focusRow(next.id);
};

const onKeydown = (event: KeyboardEvent) => {
  if (event.key === "ArrowDown") {
    event.preventDefault();
    move(1);
  } else if (event.key === "ArrowUp") {
    event.preventDefault();
    move(-1);
  } else if (event.key === "Enter") {
    // Only from a row itself: Enter in the search field or on a sort button
    // means something else, and must not use a ship the list picked for the
    // detail pane on its own.
    const id = (event.target as HTMLElement | null)?.closest<HTMLElement>(
      "[data-id]",
    )?.dataset.id;
    const item = pickable.value.find((entry) => entry.id === id);
    if (!item) return;

    event.preventDefault();
    emit("commit", item);
  }
};
</script>

<template>
  <div
    ref="root"
    class="ship-list"
    :class="{ 'ship-list--inline': inline }"
    :data-test="`ship-list-${name}`"
    @keydown="onKeydown"
  >
    <div class="ship-list__toolbar">
      <FormInput
        v-model="search"
        :name="`${name}-search`"
        :label="t('hangarPlanner.route.search')"
        :placeholder="t('hangarPlanner.route.search')"
        icon="fa-light fa-magnifying-glass"
        class="ship-list__search"
        no-label
        standalone
      />
      <BtnGroup
        segmented
        :size="BtnSizesEnum.SM"
        :aria-label="t('hangarPlanner.panel.sort')"
      >
        <Btn
          :active="sort === 'price'"
          :data-test="`ship-list-sort-price`"
          @click="sort = 'price'"
        >
          {{ priceLabel }}
        </Btn>
        <Btn
          :active="sort === 'name'"
          :data-test="`ship-list-sort-name`"
          @click="sort = 'name'"
        >
          {{ t("hangarPlanner.route.sort.name") }}
        </Btn>
      </BtnGroup>
    </div>
    <div
      v-if="chips.length > 1"
      class="ship-list__chips"
      role="group"
      :aria-label="t('hangarPlanner.pick.filters')"
    >
      <Chip
        v-for="section in chips"
        :key="section.key"
        :state="
          picked.includes(section.key)
            ? ChipStatesEnum.INCLUDED
            : ChipStatesEnum.NEUTRAL
        "
        :count="countOf(section.key)"
        :data-test="`ship-list-section-${section.key}`"
        @toggle="toggle(section.key)"
      >
        {{ section.label }}
      </Chip>
    </div>

    <div class="ship-list__body">
      <div class="ship-list__rows">
        <RowsSkeleton
          v-if="loading"
          :count="4"
          trailing
          data-test="ship-list-loading"
        />
        <p v-else-if="!items.length" class="ship-list__empty">{{ empty }}</p>
        <p v-else-if="!shownSections.length" class="ship-list__empty">
          {{ t("hangarPlanner.route.noMatch") }}
        </p>
        <template v-else>
          <section
            v-for="section in shownSections"
            :key="section.key"
            class="ship-list__section"
            :data-test="`ship-list-group-${section.key}`"
          >
            <header class="ship-list__section-head">
              <h3 class="ship-list__section-label">
                {{ section.label }} · {{ section.items.length }}
              </h3>
              <span v-if="section.hint" class="ship-list__meta">
                {{ section.hint }}
              </span>
            </header>
            <ul class="ship-list__list">
              <li
                v-for="item in section.items"
                :key="item.id"
                class="ship-list__entry"
              >
                <div
                  v-if="item.reason"
                  class="ship-list__row ship-list__row--out"
                  data-test="ship-list-out"
                >
                  <img
                    v-if="item.ship?.manufacturerIcon"
                    :src="item.ship.manufacturerIcon"
                    :alt="item.ship.manufacturerName ?? ''"
                    class="ship-list__icon"
                    loading="lazy"
                  />
                  <span class="ship-list__text">
                    <span class="ship-list__title">{{ item.title }}</span>
                    <span class="ship-list__meta">{{ item.reason }}</span>
                  </span>
                </div>
                <button
                  v-else
                  ref="rows"
                  type="button"
                  class="ship-list__row"
                  :class="{
                    'ship-list__row--selected': item.id === modelValue,
                  }"
                  :aria-pressed="item.id === modelValue"
                  :aria-expanded="inline ? item.id === modelValue : undefined"
                  :data-id="item.id"
                  data-test="ship-list-row"
                  @click="select(item)"
                  @dblclick="emit('commit', item)"
                >
                  <img
                    v-if="item.ship?.manufacturerIcon"
                    :src="item.ship.manufacturerIcon"
                    :alt="item.ship.manufacturerName ?? ''"
                    :title="item.ship.manufacturerName ?? undefined"
                    class="ship-list__icon"
                    loading="lazy"
                  />
                  <span v-else class="ship-list__icon ship-list__icon--blank">
                    <i
                      :class="item.icon ?? 'fa-light fa-rocket'"
                      aria-hidden="true"
                    />
                  </span>
                  <span class="ship-list__text">
                    <span class="ship-list__title">
                      <ShipName
                        v-if="item.ship && !item.icon"
                        :ship="item.ship"
                        :focusable="false"
                      >
                        {{ item.title }}
                      </ShipName>
                      <template v-else>{{ item.title }}</template>
                    </span>
                    <span
                      v-if="item.meta || item.tags?.length || item.badge"
                      class="ship-list__meta"
                    >
                      <span v-if="item.meta">{{ item.meta }}</span>
                      <Pill
                        v-for="tag in item.tags"
                        :key="tag.label"
                        :variant="tag.variant ?? PillVariantsEnum.NEUTRAL"
                        data-test="ship-list-tag"
                      >
                        {{ tag.label }}
                      </Pill>
                      <Pill
                        v-if="item.badge"
                        :variant="PillVariantsEnum.DEFAULT"
                      >
                        {{ item.badge }}
                      </Pill>
                    </span>
                  </span>
                  <span v-if="item.price" class="ship-list__price">
                    <strong>{{ item.price }}</strong>
                    <span v-if="item.priceNote">{{ item.priceNote }}</span>
                  </span>
                </button>
                <div
                  v-if="inline && item.id === modelValue"
                  class="ship-list__inline-detail"
                >
                  <slot name="detail" :item="item" />
                </div>
              </li>
            </ul>
          </section>
        </template>
      </div>

      <div v-if="!inline" class="ship-list__detail">
        <slot v-if="selected" name="detail" :item="selected" />
        <slot v-else name="detail-empty" />
      </div>
    </div>
  </div>
</template>

<style lang="scss" scoped>
.ship-list {
  display: flex;
  flex-direction: column;
  gap: 10px;
  min-height: 0;
}

.ship-list__toolbar {
  display: flex;
  flex-wrap: wrap;
  gap: 8px 10px;
  align-items: center;
}

.ship-list__search {
  flex: 1 1 240px;
  margin: 0;
}

.ship-list__chips {
  display: flex;
  flex-wrap: wrap;
  gap: 6px;
}

.ship-list__body {
  display: grid;
  grid-template-columns: minmax(0, 1fr) 300px;
  gap: 20px;
  align-items: start;
}

.ship-list--inline .ship-list__body {
  grid-template-columns: minmax(0, 1fr);
}

.ship-list__rows {
  display: flex;
  flex-direction: column;
  gap: 14px;
  min-width: 0;
}

.ship-list__detail {
  position: sticky;
  top: 0;
}

.ship-list__empty {
  margin: 0;
  color: var(--color-text-dim);
}

.ship-list__section {
  display: flex;
  flex-direction: column;
  gap: 6px;
}

.ship-list__section-head {
  display: flex;
  flex-wrap: wrap;
  gap: 4px 12px;
  align-items: baseline;
  justify-content: space-between;
  padding: 0 2px;
}

.ship-list__section-label {
  margin: 0;
  font-family: "Orbitron", tahoma, sans-serif;
  font-size: 0.625rem;
  font-weight: 400;
  letter-spacing: 0.16em;
  text-transform: uppercase;
  color: var(--color-text-dim);
}

.ship-list__list {
  display: flex;
  flex-direction: column;
  gap: 6px;
  margin: 0;
  padding: 0;
  list-style: none;
}

.ship-list__entry {
  display: flex;
  flex-direction: column;
  gap: 8px;
}

.ship-list__row {
  display: flex;
  gap: 12px;
  align-items: center;
  width: 100%;
  min-height: 56px;
  padding: 8px 12px;
  border: 1px solid var(--color-edge-soft);
  border-radius: 12px;
  background: var(--color-control);
  color: var(--color-text);
  font: inherit;
  text-align: left;
  cursor: pointer;

  &:hover {
    background: var(--color-control-hover);
  }

  &:focus-visible {
    outline: 2px solid var(--color-primary);
    outline-offset: 1px;
  }
}

.ship-list__row--selected {
  border-color: var(--color-primary);
  background: var(--color-control-hover);
}

.ship-list__row--out {
  border-style: dashed;
  background: transparent;
  cursor: default;

  &:hover {
    background: transparent;
  }

  .ship-list__title {
    color: var(--color-text-dim);
  }
}

.ship-list__inline-detail {
  padding: 0 4px 8px;
}

.ship-list__icon {
  flex: none;
  width: 28px;
  height: 28px;
  object-fit: contain;
}

.ship-list__icon--blank {
  display: flex;
  align-items: center;
  justify-content: center;
  color: var(--color-muted);
}

.ship-list__text {
  display: flex;
  flex: 1;
  flex-direction: column;
  gap: 2px;
  min-width: 0;
}

.ship-list__title {
  font-weight: 600;
  color: var(--color-lifted);
}

.ship-list__meta {
  display: flex;
  flex-wrap: wrap;
  gap: 4px 8px;
  align-items: center;
  font-size: 0.8rem;
  color: var(--color-text-dim);
}

.ship-list__price {
  display: flex;
  flex-direction: column;
  gap: 1px;
  align-items: flex-end;
  white-space: nowrap;

  strong {
    font-weight: 600;
    color: var(--color-lifted);
  }

  span {
    font-size: 0.75rem;
    color: var(--color-text-dim);
  }
}
</style>
