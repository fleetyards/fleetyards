<script lang="ts">
export default {
  name: "HangarPledgeItemsList",
};
</script>

<script lang="ts" setup>
import RowList from "@/shared/components/RowList/index.vue";
import RowListItem from "@/shared/components/RowListItem/index.vue";
import Btn from "@/shared/components/base/Btn/index.vue";
import CatalogueItemPopover from "@/frontend/components/CatalogueItemPopover/index.vue";
import FormCheckbox from "@/shared/components/base/FormCheckbox/index.vue";
import { BtnVariantsEnum } from "@/shared/components/base/Btn/types";
import {
  RowListItemTonesEnum,
  type RowListItemBadge,
  type RowListItemTag,
} from "@/shared/components/RowListItem/types";
import { useI18n } from "@/shared/composables/useI18n";
import { useCurrencyFormat } from "@/shared/composables/useCurrencyFormat";
import { useImageViewer } from "@/shared/composables/useImageViewer";
import { rsiHangarUrl } from "@/frontend/utils/rsiPledgeUrls";
import {
  HangarPledgeItemKindEnum,
  type HangarPledgeItem,
} from "@/services/fyApi";

type Props = {
  items: HangarPledgeItem[];
  emptyVisible?: boolean;
  emptyName?: string;
  icon: string;
  // A checkbox per row, for an action on several at once.
  selectable?: boolean;
  selectedIds?: string[];
  // "Add to inventory" on what can be kept in one, or where it went.
  inventoryActions?: boolean;
};

const props = withDefaults(defineProps<Props>(), {
  emptyVisible: false,
  emptyName: undefined,
  selectable: false,
  selectedIds: () => [],
  inventoryActions: false,
});

const emit = defineEmits<{
  toggle: [id: string];
  "add-to-inventory": [item: HangarPledgeItem];
}>();

const INVENTORY_KINDS: string[] = [
  HangarPledgeItemKindEnum.SHIP_COMPONENT,
  HangarPledgeItemKindEnum.EQUIPMENT,
];

const inventoryable = (item: HangarPledgeItem) =>
  props.inventoryActions && INVENTORY_KINDS.includes(item.kind);

const { t, l, tExists } = useI18n();

const { formatCents } = useCurrencyFormat();

const { openImage } = useImageViewer();

const viewImage = (event: MouseEvent, name: string) => {
  const image = (event.currentTarget as HTMLElement).querySelector("img");

  if (image) {
    void openImage(image, name);
  }
};

const usd = (value: number) => formatCents(Math.round(value * 100), "USD");

// A ship component matched to the catalogue says what part it is, named as
// the components catalogue names it.
const shipComponent = (item: HangarPledgeItem) =>
  item.kind === HangarPledgeItemKindEnum.SHIP_COMPONENT
    ? item.catalogueItem
    : undefined;

const categoryLabel = (category: string) => {
  const path = `labels.hardpoint.categories.${category}`;

  return tExists(path) ? t(path) : category;
};

const badges = (item: HangarPledgeItem): RowListItemBadge[] => {
  const result: RowListItemBadge[] = [];

  const size = shipComponent(item)?.size;
  if (size) {
    result.push({
      key: "size",
      label: t("labels.hardpoint.size"),
      value: size,
    });
  }

  if (item.quantity > 1) {
    result.push({
      key: "quantity",
      label: t("labels.hangarPledgeItems.quantity"),
      value: `× ${item.quantity}`,
    });
  }

  if (item.meltValue !== undefined) {
    result.push({
      key: "meltValue",
      label: t("labels.hangarPledgeItems.meltValue"),
      value: usd(item.meltValue),
    });
  } else if (item.pledgeValue !== undefined) {
    result.push({
      key: "pledgeValue",
      label: t("labels.hangarPledgeItems.pledgeValue"),
      value: usd(item.pledgeValue),
      quiet: true,
    });
  }

  if (item.pledgeCreatedOn) {
    result.push({
      key: "pledgeCreatedOn",
      label: t("labels.hangarPledgeItems.createdOn"),
      value: l(item.pledgeCreatedOn, "datetime.formats.date"),
    });
  }

  return result;
};

const tags = (item: HangarPledgeItem): RowListItemTag[] => {
  const result: RowListItemTag[] = [];

  const category = shipComponent(item)?.category;
  if (category) {
    result.push({ key: "category", label: categoryLabel(category) });
  }

  if (item.meltable) {
    result.push({
      key: "meltable",
      label: t("labels.hangarPledgeItems.meltable"),
      tone: RowListItemTonesEnum.PRIMARY,
    });
  }

  return result;
};

// Melting returns what the whole pledge is worth, so an item that came with
// others names the pledge its value belongs to.
const sub = (item: HangarPledgeItem) =>
  !item.standalone && item.pledgeName
    ? t("labels.hangarPledgeItems.partOf", { name: item.pledgeName })
    : t("labels.hangarPledgeItems.pledge", { id: item.rsiPledgeId });
</script>

<template>
  <RowList
    :records="items"
    :empty-visible="emptyVisible"
    :empty-name="emptyName"
  >
    <template #default="{ record }">
      <RowListItem
        class="pledge-item-row"
        :badges="badges(record)"
        :tags="tags(record)"
        data-test="pledge-item-row"
      >
        <template #leading>
          <FormCheckbox
            v-if="selectable"
            v-tooltip="t('labels.hangarPledgeItems.select')"
            :model-value="selectedIds.includes(record.id)"
            :aria-label="t('labels.hangarPledgeItems.select')"
            name="pledge-item-selection"
            no-label
            inline
            data-test="pledge-item-select"
            @update:model-value="emit('toggle', record.id)"
          />
          <button
            v-if="record.image"
            type="button"
            class="pledge-item-row__zoom"
            :aria-label="t('actions.viewImage', { name: record.name })"
            data-test="pledge-item-image"
            @click="viewImage($event, record.name)"
          >
            <img
              class="pledge-item-row__image"
              :src="record.image"
              alt=""
              loading="lazy"
            />
          </button>
          <span
            v-else
            class="pledge-item-row__image pledge-item-row__image--empty"
          >
            <i :class="icon" />
          </span>
        </template>

        <template #name>
          <CatalogueItemPopover
            v-if="record.catalogueItem"
            :item="{
              type: record.catalogueItem.itemType,
              slug: record.catalogueItem.slug,
              name: record.catalogueItem.name,
            }"
          >
            {{ record.name }}
          </CatalogueItemPopover>
          <template v-else>{{ record.name }}</template>
        </template>

        <template #sub>
          {{ sub(record) }}
        </template>

        <template
          v-if="
            record.kind === HangarPledgeItemKindEnum.CCU ||
            inventoryable(record)
          "
          #actions
        >
          <!-- An item added already names where it went: a second add would
               double the stock. -->
          <template v-if="inventoryable(record)">
            <Btn
              v-if="record.inventory?.slug"
              :to="{
                name: 'hangar-inventory',
                params: { inventory: record.inventory.slug },
              }"
              :variant="BtnVariantsEnum.GHOST"
              data-test="pledge-item-inventory"
            >
              <i class="fa-light fa-box-open" />
              <span>
                {{
                  t("labels.hangarPledgeItems.inInventory", {
                    name: record.inventory.name,
                  })
                }}
              </span>
            </Btn>
            <Btn
              v-else
              :variant="BtnVariantsEnum.GHOST"
              :aria-label="t('actions.hangarPledgeItems.addToInventory')"
              mobile-icon-only
              data-test="pledge-item-add-to-inventory"
              @click="emit('add-to-inventory', record)"
            >
              <i class="fa-light fa-box-open" />
              <span>{{ t("actions.hangarPledgeItems.addToInventory") }}</span>
            </Btn>
          </template>
          <!-- A CCU is applied in the RSI hangar, the next step towards the
               ship it leads to. -->
          <Btn
            v-if="record.kind === HangarPledgeItemKindEnum.CCU"
            :href="rsiHangarUrl(record)"
            :variant="BtnVariantsEnum.GHOST"
            :aria-label="t('labels.hangarPledgeItems.openOnRsi')"
            mobile-icon-only
            data-test="pledge-item-rsi-link"
          >
            <i class="fa-light fa-arrow-up-right-from-square" />
            <span>{{ t("labels.hangarPledgeItems.openOnRsi") }}</span>
          </Btn>
        </template>
      </RowListItem>
    </template>
  </RowList>
</template>

<style lang="scss" scoped>
// A paint is told apart by its colours and a piece of flair by its shape,
// neither of which a thumbnail is big enough to show.
.pledge-item-row__image {
  flex: 0 0 auto;
  width: 112px;
  height: 63px;
  object-fit: cover;
  border-radius: 4px;

  @media (min-width: 992px) {
    width: 192px;
    height: 108px;
  }
}

.pledge-item-row__zoom {
  flex: 0 0 auto;
  display: block;
  padding: 0;
  border: none;
  border-radius: 4px;
  background: none;
  cursor: zoom-in;

  &:focus-visible {
    outline: 2px solid var(--color-primary);
    outline-offset: 2px;
  }
}

// Without a picture there is nothing to make room for: the list's icon alone,
// so a list of ship components does not stand on empty frames.
.pledge-item-row__image--empty {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  width: 40px;
  height: 40px;
  font-size: 1.5rem;
  color: var(--color-muted);

  @media (min-width: 992px) {
    width: 40px;
    height: 40px;
  }
}
</style>
