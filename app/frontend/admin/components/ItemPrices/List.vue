<script lang="ts">
export default {
  name: "AdminItemPricesList",
};
</script>

<script lang="ts" setup>
import {
  InputAlignmentsEnum,
  InputTypesEnum,
} from "@/shared/components/base/FormInput/types";
import { useI18n } from "@/shared/composables/useI18n";
import { useQueryClient } from "@tanstack/vue-query";
import {
  type ItemPrice,
  type ItemPriceInput,
  type ItemPriceItemTypeEnum,
  type FilterOption,
  ItemPriceTypeEnum,
  ItemPriceTimeRangeEnum,
  useItemPrices as useItemPricesQuery,
  useCreateItemPrice as useCreateItemPriceMutation,
  useUpdateItemPrice as useUpdateItemPriceMutation,
  useDestroyItemPrice as useDestroyItemPriceMutation,
  getItemPricesQueryKey,
} from "@/services/fyAdminApi";
import BasePill from "@/shared/components/base/Pill/index.vue";
import InlineEditableList from "@/shared/components/InlineEditableList/index.vue";

interface ItemPriceFormData extends ItemPriceInput {
  timeRange?: (typeof ItemPriceTimeRangeEnum)[keyof typeof ItemPriceTimeRangeEnum];
}

type Props = {
  itemId: string;
  itemType?: ItemPriceItemTypeEnum;
};

const props = withDefaults(defineProps<Props>(), {
  itemType: "Model" as ItemPriceItemTypeEnum,
});

const { t, toUEC } = useI18n();
const queryClient = useQueryClient();

const editableList = ref<{
  editingId: string | null;
  creating: boolean;
  startCreate: () => void;
  finishEdit: () => void;
  finishCreate: () => void;
} | null>(null);

const { data, isLoading } = useItemPricesQuery({
  perPage: "100",
  q: {
    itemIdEq: props.itemId,
    itemTypeEq: props.itemType,
  },
});

const invalidateItemPrices = async () => {
  await queryClient.invalidateQueries({
    queryKey: getItemPricesQueryKey(),
  });
};

// Edit
const editForm = ref<ItemPriceFormData>({});

const onStartEdit = (record: ItemPrice) => {
  editForm.value = {
    price: record.price,
    priceType: record.priceType,
    location: record.location,
    locationUrl: record.locationUrl,
    timeRange: record.timeRange,
  };
};

const updateMutation = useUpdateItemPriceMutation({
  mutation: {
    onSettled: invalidateItemPrices,
  },
});

const onSaveEdit = async () => {
  const id = editableList.value?.editingId;
  if (!id) return;

  await updateMutation.mutateAsync({
    id,
    data: editForm.value,
  });

  editableList.value?.finishEdit();
};

// Delete
const destroyMutation = useDestroyItemPriceMutation({
  mutation: {
    onSettled: invalidateItemPrices,
  },
});

const onDestroy = async (record: ItemPrice) => {
  await destroyMutation.mutateAsync({ id: record.id });
};

// Create
const createForm = ref<ItemPriceFormData>({
  itemId: props.itemId,
  itemType: props.itemType,
  priceType: ItemPriceTypeEnum.BUY,
});

const onStartCreate = () => {
  createForm.value = {
    itemId: props.itemId,
    itemType: props.itemType,
    priceType: ItemPriceTypeEnum.BUY,
  };
};

const createMutation = useCreateItemPriceMutation({
  mutation: {
    onSettled: invalidateItemPrices,
  },
});

const onSaveCreate = async () => {
  await createMutation.mutateAsync({
    data: createForm.value,
  });

  editableList.value?.finishCreate();
};

// Dropdown options
const priceTypeOptions: FilterOption[] = Object.values(ItemPriceTypeEnum).map(
  (value) => ({
    label: value,
    value,
  }),
);

const timeRangeOptions: FilterOption[] = Object.values(
  ItemPriceTimeRangeEnum,
).map((value) => ({
  label: value,
  value,
}));

const creating = computed(() => editableList.value?.creating ?? false);

const startCreate = () => {
  editableList.value?.startCreate();
};

defineExpose({
  creating,
  startCreate,
});
</script>

<template>
  <InlineEditableList
    ref="editableList"
    empty-name="Prices"
    :loading="isLoading"
    :items="(data?.items as ItemPrice[]) || []"
    :confirm-destroy-text="t('messages.confirm.itemPrice.destroy')"
    @start-edit="onStartEdit"
    @save-edit="onSaveEdit"
    @start-create="onStartCreate"
    @save-create="onSaveCreate"
    @destroy="onDestroy"
  >
    <template #display="{ item }">
      <BasePill
        :variant="
          item.priceType === 'buy'
            ? 'success'
            : item.priceType === 'rental'
              ? 'warning'
              : 'default'
        "
        uppercase
        margin-right
        >{{ item.priceType }}</BasePill
      >
      <span v-html="toUEC(item.price)" />
      <template v-if="item.timeRange"> ({{ item.timeRange }}) </template>
      @ {{ item.location }}
      <template v-if="item.locationUrl">
        &mdash;
        <a :href="item.locationUrl" target="_blank">{{ item.locationUrl }}</a>
      </template>
    </template>

    <template #edit>
      <FilterGroup
        v-model="editForm.priceType"
        name="edit-price-type"
        :options="priceTypeOptions"
        :nullable="false"
        label="Type"
      />
      <FormInput
        v-model="editForm.price"
        name="edit-price"
        :type="InputTypesEnum.NUMBER"
        :alignment="InputAlignmentsEnum.RIGHT"
        :suffix="t('number.units.uec')"
        translation-key="itemPrice.price"
      />
      <FilterGroup
        v-if="editForm.priceType === ItemPriceTypeEnum.RENTAL"
        v-model="editForm.timeRange"
        name="edit-time-range"
        :options="timeRangeOptions"
        :nullable="false"
        label="Time Range"
      />
      <FormInput
        v-model="editForm.location"
        name="edit-location"
        translation-key="itemPrice.location"
      />
      <FormInput
        v-model="editForm.locationUrl"
        name="edit-location-url"
        translation-key="itemPrice.locationUrl"
      />
    </template>

    <template #create>
      <FilterGroup
        v-model="createForm.priceType"
        name="create-price-type"
        :options="priceTypeOptions"
        :nullable="false"
        label="Type"
      />
      <FormInput
        v-model="createForm.price"
        name="create-price"
        :type="InputTypesEnum.NUMBER"
        :alignment="InputAlignmentsEnum.RIGHT"
        :suffix="t('number.units.uec')"
        translation-key="itemPrice.price"
      />
      <FilterGroup
        v-if="createForm.priceType === ItemPriceTypeEnum.RENTAL"
        v-model="createForm.timeRange"
        name="create-time-range"
        :options="timeRangeOptions"
        :nullable="false"
        label="Time Range"
      />
      <FormInput
        v-model="createForm.location"
        name="create-location"
        translation-key="itemPrice.location"
      />
      <FormInput
        v-model="createForm.locationUrl"
        name="create-location-url"
        translation-key="itemPrice.locationUrl"
      />
    </template>
  </InlineEditableList>
</template>
