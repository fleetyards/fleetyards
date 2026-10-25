<script lang="ts">
export default {
  name: "LogisticsItemPickerRow",
};
</script>

<script lang="ts" setup>
import CommodityIcon from "@/frontend/components/Commodities/Icon/index.vue";
import EquipmentIcon from "@/frontend/components/Equipment/Icon/index.vue";
import HardpointCategoryIcon from "@/frontend/components/Models/Hardpoints/CategoryIcon/index.vue";
import RowListItem from "@/shared/components/RowListItem/index.vue";
import { type RowListItemBadge } from "@/shared/components/RowListItem/types";
import { useI18n } from "@/shared/composables/useI18n";
import { type Component as GameComponent } from "@/services/fyApi";
import { type ItemPickerEntry } from "@/frontend/components/Logistics/types";

type Props = {
  entry: ItemPickerEntry;
};

const props = defineProps<Props>();

const emit = defineEmits<{
  pick: [];
}>();

const { t, tExists, toNumber } = useI18n();

const translated = (path: string, fallback: string) =>
  tExists(path) ? t(path) : fallback;

// Every ore pod is size 1, so the size tells them apart no better than the
// name does -- what they hold does. The ROC's pods write it as `storage`.
const podCapacity = (component: GameComponent) => {
  if (component.category !== "ore_pods") return undefined;

  const data = component.typeData as
    { capacity?: number; storage?: number } | undefined;

  return data?.capacity ?? data?.storage;
};

const sub = computed(() => {
  const { entry } = props;

  if (entry.type === "Commodity") {
    const type = entry.record.commodityType;

    return [type && translated(`labels.commodity.types.${type}`, type)];
  }

  if (entry.type === "Component") {
    const { category, subType } = entry.record;

    return [
      entry.record.manufacturer?.name,
      category &&
        translated(`labels.hardpoint.categories.${category}`, category),
      subType,
    ];
  }

  return [
    entry.record.manufacturer?.name,
    entry.record.itemTypeLabel ?? entry.record.equipmentTypeLabel,
  ];
});

const subParts = computed(() =>
  sub.value.filter((part): part is string => !!part),
);

const badges = computed<RowListItemBadge[]>(() => {
  const { entry } = props;

  if (entry.type === "Commodity") return [];

  const list: RowListItemBadge[] = [];

  const capacity =
    entry.type === "Component" ? podCapacity(entry.record) : undefined;

  if (capacity) {
    list.push({
      key: "capacity",
      label: t("labels.logistics.itemPicker.capacity"),
      value: String(toNumber(capacity, "cargo")),
    });
  } else if (entry.record.size) {
    list.push({
      key: "size",
      label: t("labels.hardpoint.size"),
      value: String(entry.record.size),
    });
  }

  const grade =
    entry.type === "Component" ? entry.record.gradeLabel : entry.record.grade;

  if (grade) {
    list.push({
      key: "grade",
      label: t("labels.component.grade"),
      value: grade,
    });
  }

  return list;
});

// The item's own picture where it has one, the store image or its render.
const image = computed(() => {
  const { entry } = props;

  if (entry.type === "Component")
    return entry.record.media?.storeImage?.smallUrl;
  if (entry.type === "Equipment") return entry.record.storeImage?.smallUrl;

  return undefined;
});

// The pick button is an empty overlay, so its name has to carry what the row
// shows: two guns from different makers can share a display name.
const accessibleName = computed(() =>
  [
    props.entry.record.name,
    ...subParts.value,
    ...badges.value.map((badge) => `${badge.label} ${badge.value}`),
  ].join(", "),
);
</script>

<template>
  <RowListItem
    class="item-picker-row"
    :badges="badges"
    :data-test="`item-picker-row-${entry.record.id}`"
  >
    <template #leading>
      <img
        v-if="image"
        :src="image"
        alt=""
        class="item-picker-row__image"
        loading="lazy"
      />
      <HardpointCategoryIcon
        v-else-if="entry.type === 'Component'"
        :category="entry.record.category"
      />
      <CommodityIcon
        v-else-if="entry.type === 'Commodity'"
        :commodity="entry.record"
      />
      <EquipmentIcon v-else :equipment="entry.record" />
    </template>

    <template #name>{{ entry.record.name }}</template>

    <template #sub>
      <span v-for="part in subParts" :key="part">{{ part }}</span>
    </template>

    <!-- Over the whole row rather than wrapped around it: the row is a block of
         spans and divs, which a button may not contain. -->
    <button
      type="button"
      class="item-picker-row__pick"
      :aria-label="accessibleName"
      @click="emit('pick')"
    />
  </RowListItem>
</template>

<style lang="scss" scoped>
.item-picker-row {
  position: relative;
  cursor: pointer;
}

.item-picker-row__image {
  display: block;
  width: 64px;
  height: 36px;
  object-fit: contain;
}

.item-picker-row__pick {
  position: absolute;
  inset: 0;
  padding: 0;
  background: transparent;
  border: none;
  border-radius: inherit;
  cursor: pointer;

  &:focus-visible {
    outline: 2px solid var(--color-primary, #428bca);
    outline-offset: -2px;
  }
}
</style>
