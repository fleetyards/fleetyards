<script lang="ts">
export default {
  name: "AdminInventoryItemDetail",
};
</script>

<script lang="ts" setup>
import { useI18n } from "@/shared/composables/useI18n";
import Heading from "@/shared/components/base/Heading/index.vue";
import DetailList from "@/admin/components/DetailList/index.vue";
import { type Detail } from "@/admin/components/DetailList/types";
import VersionHistory from "@/admin/components/VersionHistory/index.vue";
import {
  type FleetInventoryItem,
  type InventoryItem,
  type VersionItemTypeEnum,
} from "@/services/fyAdminApi";

type Props = {
  /*
   * A fleet's entry and a user's carry the same ledger columns and differ only
   * in which inventory they name, so one detail serves both.
   */
  item: FleetInventoryItem | InventoryItem;
  itemType: VersionItemTypeEnum;
};

const props = defineProps<Props>();

const { t, lUtc: l } = useI18n();

const details = computed<Detail[]>(() => [
  { label: t("labels.inventoryItems.name"), value: props.item.name },
  {
    label: t("labels.inventoryItems.category"),
    value: t(`labels.inventoryItems.categories.${props.item.category}`),
  },
  {
    label: t("labels.inventoryItems.entryType"),
    value: t(`labels.inventoryItems.entryTypes.${props.item.entryType}`),
  },
  {
    label: t("labels.inventoryItems.quantity"),
    value: `${props.item.quantity} ${t(`labels.inventoryItems.units.${props.item.unit}`)}`,
  },
  { label: t("labels.inventoryItems.quality"), value: props.item.quality },
  { label: t("labels.inventoryItems.notes"), value: props.item.notes },
  { label: t("labels.inventoryItems.itemType"), value: props.item.itemType },
  {
    label: t("labels.createdAt"),
    value: l(props.item.createdAt, "datetime.formats.short"),
  },
]);
</script>

<template>
  <Heading hero class="mb-4">{{ props.item.name }}</Heading>

  <DetailList :details="details" />

  <section class="mt-10">
    <Heading class="mb-4">
      {{ t("headlines.admin.fleets.history") }}
    </Heading>

    <VersionHistory :item-id="props.item.id" :item-type="props.itemType" />
  </section>
</template>
