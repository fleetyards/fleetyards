<script lang="ts">
export default {
  name: "FleetContractsItemsForm",
};
</script>

<script lang="ts" setup>
import Btn from "@/shared/components/base/Btn/index.vue";
import FormInput from "@/shared/components/base/FormInput/index.vue";
import BaseSelect from "@/shared/components/base/Select/index.vue";
import {
  type Fleet,
  type FilterOption,
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

const name = ref("");
const category = ref<InventoryCategoryEnum>(InventoryCategoryEnum.COMMODITY);
const unit = ref<InventoryUnitEnum>(InventoryUnitEnum.SCU);
const quantity = ref("");
const minQuality = ref("");

const categoryOptions = computed<FilterOption[]>(() =>
  Object.values(InventoryCategoryEnum).map((value) => ({
    value,
    label: t(`labels.fleets.contracts.category.${value}`),
  })),
);

const unitOptions = computed<FilterOption[]>(() =>
  Object.values(InventoryUnitEnum).map((value) => ({
    value,
    label: t(`labels.fleets.contracts.unit.${value}`),
  })),
);

// Only a crafting contract can demand a grade; asking for one on a haul would
// silently stop counting deposits recorded without a quality.
const showQuality = computed(() => props.contract.kind === "crafting");

const createItem = useCreateFleetContractItem();
const destroyItem = useDestroyFleetContractItem();

const reset = () => {
  name.value = "";
  quantity.value = "";
  minQuality.value = "";
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
        <span class="contract-items__quantity">
          {{ Number(item.quantity) }}
          {{ t(`labels.fleets.contracts.unit.${item.unit}`) }}
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
      <div class="col-12 col-md-4">
        <FormInput
          v-model="name"
          name="itemName"
          :label="t('labels.fleets.contracts.itemName')"
        />
      </div>
      <div class="col-12 col-md-3">
        <BaseSelect
          v-model="category"
          :options="categoryOptions"
          :label="t('labels.fleets.contracts.itemCategory')"
          name="itemCategory"
          :searchable="false"
        />
      </div>
      <div class="col-12 col-md-2">
        <BaseSelect
          v-model="unit"
          :options="unitOptions"
          :label="t('labels.fleets.contracts.itemUnit')"
          name="itemUnit"
          :searchable="false"
        />
      </div>
      <div class="col-12 col-md-3">
        <FormInput
          v-model="quantity"
          name="itemQuantity"
          type="number"
          :label="t('labels.fleets.contracts.itemQuantity')"
        />
      </div>
      <div v-if="showQuality" class="col-12 col-md-3">
        <FormInput
          v-model="minQuality"
          name="itemMinQuality"
          type="number"
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
