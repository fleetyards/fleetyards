<script lang="ts">
export default {
  name: "EquipmentCard",
};
</script>

<script lang="ts" setup>
import EquipmentIcon from "@/frontend/components/Equipment/Icon/index.vue";
import Chip from "@/shared/components/base/Chip/index.vue";
import { ChipStatesEnum } from "@/shared/components/base/Chip/types";
import ItemCard from "@/shared/components/ItemCard/index.vue";
import CartAddToCart from "@/frontend/components/Cart/AddToCart/index.vue";
import {
  type ItemCardFacet,
  type ItemCardMaker,
} from "@/shared/components/ItemCard/types";
import { useEquipmentBadges } from "@/frontend/composables/useEquipmentBadges";
import { useEquipmentStats } from "@/frontend/composables/useEquipmentStats";
import { useI18n } from "@/shared/composables/useI18n";
import { type Equipment, InventoryItemTypeEnum } from "@/services/fyApi";

type Props = {
  equipment: Equipment;
  details?: boolean;
};

const props = withDefaults(defineProps<Props>(), { details: false });

const { t } = useI18n();

const route = useRoute();

// As in the row: a value the catalogue is narrowed by narrows it when clicked,
// and `page` is dropped because the result set it counted is gone.
const filterLink = (key: string, value: string) => ({
  name: route.name as string,
  query: { ...route.query, page: undefined, [key]: value },
});

const badges = useEquipmentBadges(() => props.equipment);

const stats = useEquipmentStats(() => props.equipment);

const maker = computed<ItemCardMaker | undefined>(() => {
  const { manufacturer } = props.equipment;
  if (!manufacturer) return undefined;

  const { icon, logo } = manufacturer;

  return {
    name: manufacturer.name,
    code: manufacturer.code || manufacturer.shortName || undefined,
    logo: icon?.smallUrl || icon?.url || logo?.smallUrl || logo?.url,
    to: manufacturer.slug
      ? filterLink("manufacturerSlugIn", manufacturer.slug)
      : undefined,
  };
});

const categories = computed<ItemCardFacet[]>(() => {
  const { equipmentType, equipmentTypeLabel, itemType, itemTypeLabel } =
    props.equipment;
  const list: ItemCardFacet[] = [];

  if (equipmentType && equipmentTypeLabel) {
    list.push({
      key: "equipmentType",
      label: equipmentTypeLabel,
      to: filterLink("equipmentTypeIn", equipmentType),
    });
  }

  if (itemType && itemTypeLabel) {
    list.push({
      key: "itemType",
      label: itemTypeLabel,
      to: filterLink("itemTypeIn", itemType),
    });
  }

  return list;
});

const image = computed(
  () =>
    props.equipment.storeImage?.mediumUrl ||
    props.equipment.storeImage?.smallUrl,
);
</script>

<template>
  <ItemCard
    class="equipment-card"
    :data-test="`equipment-card-${equipment.slug}`"
    :to="{ name: 'equipment-item', params: { slug: equipment.slug } }"
    :image="image"
    :maker="maker"
    :categories="categories"
    :badges="badges"
    :stats="stats"
    :details="details"
  >
    <template #name>{{ equipment.name }}</template>

    <template #icon>
      <EquipmentIcon :equipment="equipment" />
    </template>

    <template v-if="equipment.retired" #tags>
      <Chip :state="ChipStatesEnum.EXCLUDED">
        {{ t("labels.equipment.retired") }}
      </Chip>
    </template>

    <template #actions>
      <CartAddToCart
        :item="{
          id: equipment.id,
          type: InventoryItemTypeEnum.EQUIPMENT,
          name: equipment.name,
        }"
      />
    </template>
  </ItemCard>
</template>
