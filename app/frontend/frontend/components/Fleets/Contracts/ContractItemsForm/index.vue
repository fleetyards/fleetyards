<script lang="ts">
export default {
  name: "FleetContractsItemsForm",
};
</script>

<script lang="ts" setup>
import Btn from "@/shared/components/base/Btn/index.vue";
import FormInput from "@/shared/components/base/FormInput/index.vue";
import { InputTypesEnum } from "@/shared/components/base/FormInput/types";
import BaseSelect from "@/shared/components/base/Select/index.vue";
import ComponentPicker from "@/frontend/components/Logistics/ComponentPicker/index.vue";
import CommodityPicker from "@/frontend/components/Logistics/CommodityPicker/index.vue";
import EquipmentPicker from "@/frontend/components/Logistics/EquipmentPicker/index.vue";
import { type PickedItem } from "@/frontend/components/Logistics/types";
import { useInventoryOptions } from "@/frontend/composables/useInventoryOptions";
import {
  type Fleet,
  type Commodity,
  type Equipment as GameEquipment,
  type Component as GameComponent,
  type FleetContractDetail,
  type FleetContractItem,
  InventoryCategoryEnum,
  InventoryUnitEnum,
  useCreateFleetContractItem,
  useDestroyFleetContractItem,
} from "@/services/fyApi";
import { useI18n } from "@/shared/composables/useI18n";
import { useAppNotifications } from "@/shared/composables/useAppNotifications";

type Props = {
  fleet: Fleet;
  contract: FleetContractDetail;
};

const props = defineProps<Props>();
const emit = defineEmits<{ changed: [] }>();

const { t } = useI18n();
const { displayAlert } = useAppNotifications();
const { categoryOptions, unitOptionsFor } = useInventoryOptions();

const name = ref("");
const category = ref<InventoryCategoryEnum>(InventoryCategoryEnum.COMMODITY);
const unit = ref<InventoryUnitEnum>(InventoryUnitEnum.SCU);
const quantity = ref("");
const minQuality = ref("");

// The catalogue entry this line asks for, when it asks for one. Same slot and
// same rules as `Logistics/InventoryItemModal`, so a contract names goods the
// way the ledger names them.
const pickedItem = ref<PickedItem | undefined>(undefined);

const unitOptions = unitOptionsFor(category);

// The category dictates which units make sense, so a category change pulls the
// unit along rather than leaving a pairing the API rejects.
watch(unitOptions, (options) => {
  if (options.some((option) => option.value === unit.value)) return;

  unit.value = options[0].value as InventoryUnitEnum;
});

const isComponent = computed(
  () => category.value === InventoryCategoryEnum.COMPONENT,
);

const isCommodity = computed(
  () => category.value === InventoryCategoryEnum.COMMODITY,
);

// One table backs all three: the game files file magazines as weapon
// attachments, so ammunition is not a catalogue of its own.
const EQUIPMENT_CATEGORIES: InventoryCategoryEnum[] = [
  InventoryCategoryEnum.WEAPON,
  InventoryCategoryEnum.EQUIPMENT,
  InventoryCategoryEnum.AMMUNITION,
];

const isEquipment = computed(() =>
  EQUIPMENT_CATEGORIES.includes(category.value),
);

const EQUIPMENT_TYPES_FOR_CATEGORY: Record<string, string[]> = {
  [InventoryCategoryEnum.WEAPON]: ["weapon"],
  [InventoryCategoryEnum.AMMUNITION]: ["weapon_attachment"],
  [InventoryCategoryEnum.EQUIPMENT]: [
    "armor",
    "clothing",
    "undersuit",
    "tool",
    "medical",
    "hacking_tool",
  ],
};

const equipmentTypes = computed(
  () => EQUIPMENT_TYPES_FOR_CATEGORY[category.value] || [],
);

const applyPickedComponent = (component: GameComponent) => {
  pickedItem.value = {
    type: "Component",
    id: component.id,
    name: component.name,
  };
  name.value = component.name;
};

const applyPickedCommodity = (commodity: Commodity) => {
  pickedItem.value = {
    type: "Commodity",
    id: commodity.id,
    name: commodity.name,
  };
  name.value = commodity.name;
};

const applyPickedEquipment = (equipment: GameEquipment) => {
  pickedItem.value = {
    type: "Equipment",
    id: equipment.id,
    name: equipment.name,
  };
  name.value = equipment.name;
};

// A hand-edited name no longer describes the picked item, so the reference goes
// with it rather than mislabeling a real catalogue entry. Asking for something
// the catalogue does not carry stays allowed; it just is not a reference.
watch(name, (val) => {
  if (pickedItem.value && val !== pickedItem.value.name) {
    pickedItem.value = undefined;
  }
});

// Switching away from the category that offered the picker leaves the reference
// pointing at the wrong kind of thing.
watch([isComponent, isCommodity, isEquipment], () => {
  if (!pickedItem.value) return;

  const stillOffered = {
    Component: isComponent.value,
    Commodity: isCommodity.value,
    Equipment: isEquipment.value,
  }[pickedItem.value.type];

  if (!stillOffered) pickedItem.value = undefined;
});

// Only a crafting contract can demand a grade; asking for one on a haul would
// silently stop counting deposits recorded without a quality.
const showQuality = computed(() => props.contract.kind === "crafting");

const createItem = useCreateFleetContractItem();
const destroyItem = useDestroyFleetContractItem();

const reset = () => {
  name.value = "";
  quantity.value = "";
  minQuality.value = "";
  pickedItem.value = undefined;
};

const addItem = async () => {
  if (!name.value || !quantity.value) return;

  await createItem
    .mutateAsync({
      fleetSlug: props.fleet.slug,
      fleetContractSlug: props.contract.slug,
      data: {
        name: name.value,
        category: category.value as never,
        unit: unit.value as never,
        quantity: quantity.value,
        minQuality:
          showQuality.value && minQuality.value
            ? Number(minQuality.value)
            : null,
        itemType: pickedItem.value?.type,
        itemId: pickedItem.value?.id,
      },
    })
    .then(() => {
      reset();
      emit("changed");
    })
    .catch(() => {
      displayAlert({ text: t("messages.fleets.contract.item.create.failure") });
    });
};

const removeItem = async (item: FleetContractItem) => {
  await destroyItem
    .mutateAsync({
      fleetSlug: props.fleet.slug,
      fleetContractSlug: props.contract.slug,
      id: item.id,
    })
    .then(() => emit("changed"))
    .catch(() => {
      displayAlert({
        text: t("messages.fleets.contract.item.destroy.failure"),
      });
    });
};
</script>

<template>
  <div class="contract-items" data-test="contract-items">
    <ul class="contract-items__list">
      <li
        v-for="item in props.contract.items"
        :key="item.id"
        class="contract-items__row"
        data-test="contract-item"
      >
        <span class="contract-items__name">{{ item.name }}</span>
        <!-- What the ledger will be matched against, and whether it is a real
             catalogue entry or a name somebody typed. -->
        <span class="contract-items__category">
          {{ t(`labels.logistics.categories.${item.category}`) }}
        </span>
        <span v-if="item.item" class="contract-items__reference">
          <i class="fa-duotone fa-link" />
          {{ t(`labels.fleets.contracts.itemTypes.${item.item.type}`) }}
        </span>
        <span class="contract-items__quantity">
          {{ Number(item.quantity) }}
          {{ t(`labels.logistics.units.${item.unit}`) }}
        </span>
        <span v-if="item.minQuality" class="contract-items__quality">
          {{
            t("labels.fleets.contracts.minQuality", { value: item.minQuality })
          }}
        </span>
        <Btn size="xs" @click="removeItem(item)">
          {{ t("actions.remove") }}
        </Btn>
      </li>
    </ul>

    <div class="row">
      <div class="col-12 col-md-6">
        <BaseSelect
          v-model="category"
          :options="categoryOptions"
          :label="t('labels.fleets.contracts.itemCategory')"
          name="itemCategory"
          :searchable="false"
        />
      </div>
      <div class="col-12 col-md-6">
        <BaseSelect
          v-model="unit"
          :options="unitOptions"
          :label="t('labels.fleets.contracts.itemUnit')"
          name="itemUnit"
          :searchable="false"
        />
      </div>
    </div>

    <!-- Pick the goods out of the catalogue the category names, so the contract
         records which commodity or item it wants rather than a typed string. -->
    <ComponentPicker v-if="isComponent" @select="applyPickedComponent" />
    <CommodityPicker v-if="isCommodity" @select="applyPickedCommodity" />
    <EquipmentPicker
      v-if="isEquipment"
      :equipment-types="equipmentTypes"
      @select="applyPickedEquipment"
    />

    <div class="row">
      <div class="col-12 col-md-6">
        <FormInput
          v-model="name"
          name="itemName"
          :label="t('labels.fleets.contracts.itemName')"
        />
      </div>
      <div class="col-12 col-md-3">
        <FormInput
          v-model="quantity"
          name="itemQuantity"
          :type="InputTypesEnum.NUMBER"
          :min="0"
          :label="t('labels.fleets.contracts.itemQuantity')"
        />
      </div>
      <div v-if="showQuality" class="col-12 col-md-3">
        <FormInput
          v-model="minQuality"
          name="itemMinQuality"
          :type="InputTypesEnum.NUMBER"
          :min="0"
          :max="1000"
          :label="t('labels.fleets.contracts.itemMinQuality')"
        />
      </div>
    </div>

    <Btn data-test="add-contract-item" @click="addItem">
      <i class="fa-light fa-plus" />
      <span>{{ t("actions.fleets.contracts.addItem") }}</span>
    </Btn>
  </div>
</template>

<style lang="scss" scoped>
@import "index";
</style>
