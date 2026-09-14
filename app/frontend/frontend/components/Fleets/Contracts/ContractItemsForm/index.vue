<script lang="ts">
export default {
  name: "FleetContractsItemsForm",
};
</script>

<script lang="ts" setup>
import InlineEditableList from "@/shared/components/InlineEditableList/index.vue";
import Btn from "@/shared/components/base/Btn/index.vue";
import { BtnVariantsEnum } from "@/shared/components/base/Btn/types";
import FormInput from "@/shared/components/base/FormInput/index.vue";
import { InputTypesEnum } from "@/shared/components/base/FormInput/types";
import BaseSelect from "@/shared/components/base/Select/index.vue";
import { BaseSelectVariantsEnum } from "@/shared/components/base/Select/types";
import BasePill from "@/shared/components/base/Pill/index.vue";
import { PillVariantsEnum } from "@/shared/components/base/Pill/types";
import ComponentPicker from "@/frontend/components/Logistics/ComponentPicker/index.vue";
import CommodityPicker from "@/frontend/components/Logistics/CommodityPicker/index.vue";
import EquipmentPicker from "@/frontend/components/Logistics/EquipmentPicker/index.vue";
import { type PickedItem } from "@/frontend/components/Logistics/types";
import { useInventoryOptions } from "@/frontend/composables/useInventoryOptions";
import { validationErrorFrom } from "@/shared/utils/ApiErrors";
import { useI18n } from "@/shared/composables/useI18n";
import { useAppNotifications } from "@/shared/composables/useAppNotifications";
import {
  type Fleet,
  type Commodity,
  type Equipment as GameEquipment,
  type Component as GameComponent,
  type FilterOption,
  type FleetContractDetail,
  type FleetContractItem,
  InventoryCategoryEnum,
  InventoryUnitEnum,
  FleetContractQualityMatchEnum,
  useCreateFleetContractItem,
  useDestroyFleetContractItem,
} from "@/services/fyApi";

type Props = {
  fleet: Fleet;
  contract: FleetContractDetail;
};

const props = defineProps<Props>();
const emit = defineEmits<{ changed: [] }>();

const { t } = useI18n();
const { displayAlert } = useAppNotifications();
const { categoryOptions, unitOptionsFor } = useInventoryOptions();

const editableList = ref<{
  creating: boolean;
  startCreate: () => void;
  finishCreate: () => void;
} | null>(null);

// The list does not carry an add control of its own -- every consumer drives
// it from outside, the way `admin/components/ItemPrices` does.
const creating = computed(() => editableList.value?.creating ?? false);

const isCrafting = computed(() => props.contract.kind === "crafting");

// A commodity is the one thing you cannot craft — those are mined, bought or
// hauled. Written as an exclusion so a category added to the ledger later is
// craftable by default.
const UNCRAFTABLE_CATEGORIES: string[] = [InventoryCategoryEnum.COMMODITY];

const availableCategories = computed(() =>
  isCrafting.value
    ? categoryOptions.value.filter(
        (option) => !UNCRAFTABLE_CATEGORIES.includes(option.value as string),
      )
    : categoryOptions.value,
);

const blankForm = () => ({
  name: "",
  category: (isCrafting.value
    ? InventoryCategoryEnum.COMPONENT
    : InventoryCategoryEnum.COMMODITY) as InventoryCategoryEnum,
  unit: InventoryUnitEnum.SCU as InventoryUnitEnum,
  quantity: "1",
  quality: "",
  qualityMatch: FleetContractQualityMatchEnum.AT_LEAST,
});

const createForm = ref(blankForm());

// The catalogue entry this line asks for, when it asks for one. Same slot and
// same rules as `Logistics/InventoryItemModal`, so a contract names goods the
// way the ledger names them.
const pickedItem = ref<PickedItem | undefined>(undefined);

const category = computed(() => createForm.value.category);

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

// Unfiltered while crafting: a Galant is a `weapon`, so under an "Equipment"
// filtered to armour and tools it could be neither searched for nor scrolled
// to. The pick then decides the category (see `categoryForEquipment`).
const equipmentTypes = computed(() =>
  isCrafting.value ? [] : EQUIPMENT_TYPES_FOR_CATEGORY[category.value] || [],
);

// Which ledger category a piece of equipment is deposited under. It has to be
// the depositor's word: `Contracts::Progress` matches on (name, category,
// unit), so a line filed as `equipment` would never see a rifle the courier's
// ledger recorded as `weapon`.
const categoryForEquipment = (equipmentType?: string | null) => {
  if (equipmentType === "weapon") return InventoryCategoryEnum.WEAPON;
  if (equipmentType === "weapon_attachment") {
    return InventoryCategoryEnum.AMMUNITION;
  }

  return InventoryCategoryEnum.EQUIPMENT;
};

const unitOptions = unitOptionsFor(category);

// The category dictates which units make sense, so a category change pulls the
// unit along instead of leaving a pairing the API would reject.
watch(unitOptions, (options) => {
  if (options.some((option) => option.value === createForm.value.unit)) return;

  createForm.value.unit = options[0].value as InventoryUnitEnum;
});

const qualityMatchOptions = computed<FilterOption[]>(() =>
  Object.values(FleetContractQualityMatchEnum).map((value) => ({
    value,
    label: t(`labels.fleets.contracts.qualityMatches.${value}`),
  })),
);

const applyPicked = (item: PickedItem) => {
  pickedItem.value = item;
  createForm.value.name = item.name;
};

const applyPickedComponent = (component: GameComponent) =>
  applyPicked({ type: "Component", id: component.id, name: component.name });

const applyPickedCommodity = (commodity: Commodity) =>
  applyPicked({ type: "Commodity", id: commodity.id, name: commodity.name });

const applyPickedEquipment = (equipment: GameEquipment) => {
  applyPicked({ type: "Equipment", id: equipment.id, name: equipment.name });

  if (isCrafting.value) {
    createForm.value.category = categoryForEquipment(equipment.equipmentType);
  }
};

// A hand-edited name no longer describes the picked item, so the reference goes
// with it rather than mislabelling a real catalogue entry.
watch(
  () => createForm.value.name,
  (val) => {
    if (pickedItem.value && val !== pickedItem.value.name) {
      pickedItem.value = undefined;
    }
  },
);

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

const createItem = useCreateFleetContractItem();
const destroyItem = useDestroyFleetContractItem();

const onStartCreate = () => {
  createForm.value = blankForm();
  pickedItem.value = undefined;
};

const onSaveCreate = async () => {
  await createItem
    .mutateAsync({
      fleetSlug: props.fleet.slug,
      fleetContractSlug: props.contract.slug,
      data: {
        name: createForm.value.name,
        category: createForm.value.category,
        unit: createForm.value.unit,
        quantity: createForm.value.quantity,
        quality: createForm.value.quality
          ? Number(createForm.value.quality)
          : null,
        qualityMatch: createForm.value.qualityMatch,
        itemType: pickedItem.value?.type,
        itemId: pickedItem.value?.id,
      },
    })
    .then(() => {
      editableList.value?.finishCreate();
      emit("changed");
    })
    .catch((error) => {
      // The API says *why* — asking for the same goods twice is the common
      // refusal, and a generic toast leaves the author guessing.
      const { message } = validationErrorFrom(error);

      displayAlert({
        text: message || t("messages.fleets.contract.item.create.failure"),
      });
    });
};

const onDestroy = async (item: FleetContractItem) => {
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

const qualityLabel = (item: FleetContractItem) =>
  t(
    item.qualityMatch === FleetContractQualityMatchEnum.EXACT
      ? "labels.fleets.contracts.exactQuality"
      : "labels.fleets.contracts.minQuality",
    { value: item.quality as number },
  );
</script>

<template>
  <InlineEditableList
    ref="editableList"
    data-test="contract-items"
    :items="props.contract.items"
    :empty-name="t('headlines.fleets.contracts.items')"
    :confirm-destroy-text="t('messages.confirm.fleets.contractItem.destroy')"
    hide-edit
    @start-create="onStartCreate"
    @save-create="onSaveCreate"
    @destroy="onDestroy"
  >
    <template #display="{ item }">
      <BasePill :variant="PillVariantsEnum.NEUTRAL" uppercase margin-right>
        {{ t(`labels.logistics.categories.${item.category}`) }}
      </BasePill>
      <span class="contract-items__name">{{ item.name }}</span>
      <span class="contract-items__quantity">
        {{ Number(item.quantity) }}
        {{ t(`labels.logistics.units.${item.unit}`) }}
      </span>
      <!-- Whether this is a real catalogue entry or a name somebody typed. -->
      <span v-if="item.item" class="contract-items__reference">
        <i class="fa-duotone fa-link" />
        {{ t(`labels.fleets.contracts.itemTypes.${item.item.type}`) }}
      </span>
      <span v-if="item.quality != null" class="contract-items__quality">
        {{ qualityLabel(item) }}
      </span>
    </template>

    <template #create>
      <FormInput
        v-model="createForm.name"
        name="create-item-name"
        :label="t('labels.fleets.contracts.itemName')"
      />

      <BaseSelect
        v-model="createForm.category"
        name="create-item-category"
        :options="availableCategories"
        :label="t('labels.logistics.category')"
        :nullable="false"
        :searchable="false"
      />

      <ComponentPicker v-if="isComponent" @select="applyPickedComponent" />
      <CommodityPicker v-if="isCommodity" @select="applyPickedCommodity" />
      <EquipmentPicker
        v-if="isEquipment"
        :equipment-types="equipmentTypes"
        @select="applyPickedEquipment"
      />

      <FormInput
        v-model="createForm.quantity"
        name="create-item-quantity"
        :type="InputTypesEnum.NUMBER"
        :label="t('labels.logistics.quantity')"
        :min="0"
        no-placeholder
      >
        <template #suffix>
          <BaseSelect
            v-if="unitOptions.length > 1"
            v-model="createForm.unit"
            :options="unitOptions"
            :label="t('labels.logistics.unit')"
            :variant="BaseSelectVariantsEnum.AFFIX"
            name="create-item-unit"
            :nullable="false"
            no-label
          />
          <span v-else class="base-input__suffix-text">
            {{ t(`labels.logistics.units.${createForm.unit}`) }}
          </span>
        </template>
      </FormInput>

      <!-- The grade, and how it is read. Offered on every kind, because the
           ledger records one on every entry; blank asks for any. -->
      <FormInput
        v-model="createForm.quality"
        name="create-item-quality"
        :type="InputTypesEnum.NUMBER"
        :label="t('labels.logistics.quality')"
        :min="0"
        :step="1"
        :max="1000"
        no-placeholder
      >
        <template #prefix>
          <!-- FormInput wraps its suffix slot but not its prefix one, so an
               unwrapped affix select would take the whole field. -->
          <div class="base-input__prefix">
            <BaseSelect
              v-model="createForm.qualityMatch"
              :options="qualityMatchOptions"
              :label="t('labels.fleets.contracts.qualityMatch')"
              :variant="BaseSelectVariantsEnum.AFFIX"
              name="create-item-quality-match"
              :nullable="false"
              no-label
              :searchable="false"
            />
          </div>
        </template>
      </FormInput>
    </template>
  </InlineEditableList>

  <Btn
    v-if="!creating"
    data-test="add-item"
    :variant="BtnVariantsEnum.GHOST"
    @click="editableList?.startCreate()"
  >
    <i class="fa-duotone fa-plus" />
    {{ t("actions.fleets.contracts.addItem") }}
  </Btn>
</template>

<style lang="scss" scoped>
@import "index";
</style>
