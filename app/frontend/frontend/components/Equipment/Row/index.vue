<script lang="ts">
export default {
  name: "EquipmentRow",
};
</script>

<script lang="ts" setup>
import CatalogueItemPopover from "@/frontend/components/CatalogueItemPopover/index.vue";
import EquipmentIcon from "@/frontend/components/Equipment/Icon/index.vue";
import EquipmentLeadMetric from "@/frontend/components/Equipment/LeadMetric/index.vue";
import Chip from "@/shared/components/base/Chip/index.vue";
import { ChipStatesEnum } from "@/shared/components/base/Chip/types";
import { manufacturerMark } from "@/frontend/utils/manufacturerMark";
import RowListItem from "@/shared/components/RowListItem/index.vue";
import CartAddToCart from "@/frontend/components/Cart/AddToCart/index.vue";
import { useEquipmentBadges } from "@/frontend/composables/useEquipmentBadges";
import { useI18n } from "@/shared/composables/useI18n";
import { type Equipment, InventoryItemTypeEnum } from "@/services/fyApi";

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

const badges = useEquipmentBadges(() => props.equipment);

const manufacturerLogo = computed(() =>
  manufacturerMark(props.equipment.manufacturer),
);
</script>

<template>
  <RowListItem
    class="equipment-row"
    :to="{ name: 'equipment-item', params: { slug: equipment.slug } }"
    :badges="badges"
  >
    <template #leading>
      <span class="equipment-row__thumb">
        <img
          v-if="equipment.storeImage?.smallUrl"
          class="equipment-row__image"
          :src="equipment.storeImage.smallUrl"
          alt=""
          loading="lazy"
          data-test="equipment-row-image"
        />
        <EquipmentIcon
          v-else
          :equipment="equipment"
          class="equipment-row__icon"
        />
      </span>
    </template>

    <!-- The name is already the row's link, so it opens the card without
         a second link or focus stop of its own. -->
    <template #name>
      <CatalogueItemPopover
        :item="{
          type: 'Equipment',
          slug: equipment.slug,
          name: equipment.name,
        }"
        :record="equipment"
        :link="false"
        :focusable="false"
      >
        {{ equipment.name }}
      </CatalogueItemPopover>
    </template>

    <template #sub>
      <router-link
        v-if="equipment.manufacturer?.slug"
        :to="filterLink('manufacturerSlugIn', equipment.manufacturer.slug)"
      >
        <img
          v-if="manufacturerLogo"
          class="equipment-row__maker-logo"
          :src="manufacturerLogo"
          alt=""
          loading="lazy"
          data-test="equipment-row-maker-logo"
        />
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

    <template #actions>
      <CartAddToCart
        :item="{
          id: equipment.id,
          type: InventoryItemTypeEnum.EQUIPMENT,
          name: equipment.name,
        }"
        variant="row"
      />
    </template>
  </RowListItem>
</template>

<style lang="scss" scoped>
// The figures drop out on a narrow screen rather than squeezing the name.
.equipment-row {
  // The same box with or without a picture, so every row is one height and
  // every name starts on one edge.
  &__thumb {
    display: flex;
    flex: none;
    align-items: center;
    justify-content: center;
    width: 112px;
    height: 63px;
  }

  &__icon {
    --equipment-icon-size: 36px;
  }

  &__image {
    width: 100%;
    height: 100%;
    // Mostly a game-file render: transparent and cut tight to the item, so it
    // is fitted rather than cropped.
    object-fit: contain;
    border-radius: 4px;
  }

  // Sized to the line it sits on, so a row with a logo is no taller than one
  // without.
  &__maker-logo {
    display: inline-block;
    width: 18px;
    height: 18px;
    margin-right: 4px;
    object-fit: contain;
    vertical-align: -4px;
  }

  // May shrink, so four figures wrap in their own block before they push the
  // row's facts onto a second line. The name keeps its floor.
  :deep(.component-lead-metric) {
    display: none;
    flex: 0 1 auto;
    min-width: 0;

    @media (min-width: 992px) {
      display: flex;
    }
  }
}
</style>
