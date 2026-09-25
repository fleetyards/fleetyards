<script lang="ts">
export default {
  name: "EquipmentRow",
};
</script>

<script lang="ts" setup>
import EquipmentIcon from "@/frontend/components/Equipment/Icon/index.vue";
import EquipmentLeadMetric from "@/frontend/components/Equipment/LeadMetric/index.vue";
import Chip from "@/shared/components/base/Chip/index.vue";
import { ChipStatesEnum } from "@/shared/components/base/Chip/types";
import RowListItem from "@/shared/components/RowListItem/index.vue";
import { type RowListItemBadge } from "@/shared/components/RowListItem/types";
import { useI18n } from "@/shared/composables/useI18n";
import { type Equipment } from "@/services/fyApi";

type Props = {
  equipment: Equipment;
};

const props = defineProps<Props>();

const { t } = useI18n();

const route = useRoute();

// Every value the catalogue can be narrowed by is a link that narrows it, and
// the filters live in the route query. `page` is dropped: the row that was
// clicked is almost never on the same page of a smaller result set.
const filterLink = (key: string, value: string) => ({
  name: route.name as string,
  query: { ...route.query, page: undefined, [key]: value },
});

const badges = computed<RowListItemBadge[]>(() => {
  const list: RowListItemBadge[] = [];

  if (props.equipment.slotLabel) {
    list.push({
      key: "slot",
      label: t("labels.equipment.slot"),
      value: props.equipment.slotLabel,
    });
  }

  if (props.equipment.size) {
    list.push({
      key: "size",
      label: t("labels.equipment.size"),
      value: props.equipment.size,
    });
  }

  if (props.equipment.grade) {
    list.push({
      key: "grade",
      label: t("labels.equipment.grade"),
      value: props.equipment.grade,
    });
  }

  return list;
});
</script>

<template>
  <RowListItem
    class="equipment-row"
    :to="{ name: 'equipment-item', params: { slug: equipment.slug } }"
    :badges="badges"
  >
    <template #leading>
      <EquipmentIcon :equipment="equipment" />
    </template>

    <template #name>{{ equipment.name }}</template>

    <template #sub>
      <router-link
        v-if="equipment.manufacturer?.slug"
        :to="filterLink('manufacturerSlugIn', equipment.manufacturer.slug)"
      >
        {{ equipment.manufacturer.name }}
      </router-link>
      <router-link
        v-if="equipment.equipmentType"
        :to="filterLink('equipmentTypeIn', equipment.equipmentType)"
      >
        {{ equipment.equipmentTypeLabel }}
      </router-link>
      <router-link
        v-if="equipment.itemType"
        :to="filterLink('itemTypeIn', equipment.itemType)"
      >
        {{ equipment.itemTypeLabel }}
      </router-link>
      <Chip v-if="equipment.retired" :state="ChipStatesEnum.EXCLUDED">
        {{ t("labels.equipment.retired") }}
      </Chip>
    </template>

    <EquipmentLeadMetric :equipment="equipment" />
  </RowListItem>
</template>

<style lang="scss" scoped>
// The figures drop out on a narrow screen rather than squeezing the name.
.equipment-row {
  :deep(.component-lead-metric) {
    display: none;
    flex: none;

    @media (min-width: 992px) {
      display: flex;
    }
  }
}
</style>
