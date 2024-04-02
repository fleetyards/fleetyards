<template>
  <Modal v-if="shopCommodity" ref="modal" :title="title" class="prices-modal">
    <form @submit.prevent="onSubmit">
      <div v-for="record in prices" :key="record.id" class="price-item">
        <!-- eslint-disable vue/no-v-html -->
        <span
          v-if="record.price"
          class="price-label"
          v-html="toUEC(record.price)"
        />
        <!-- eslint-enable vue/no-v-html -->
        <span v-if="record.timeRange" class="time-range-label">
          {{ record.timeRange }}
        </span>
        <span class="date-label">
          {{ l(record.createdAt) }}
        </span>
        <span
          v-tooltip="t('labels.shopCommodity.confirmed')"
          class="confirmed-label"
        >
          <i v-if="record.confirmed" class="fal fa-check" />
          <i v-else class="fal fa-times" />
        </span>
        <Btn size="small" inline @click="handleDestroy(record)">
          <i class="fa fa-times" />
        </Btn>
      </div>
      <div class="new-price">
        <FormInput
          v-model="price"
          name="price"
          class="input"
          type="number"
          :no-label="true"
          :autofocus="true"
          translation-key="commodityPrice.price"
        />
        <FilterGroup
          v-if="path === 'rental'"
          v-model="timeRange"
          name="timeRange"
          :options="timeRanges"
          :no-label="true"
        />
        <Btn size="small" type="submit">
          <i class="fa fa-check" />
        </Btn>
      </div>
    </form>
  </Modal>
</template>

<script lang="ts" setup>
import Btn from "@/shared/components/base/Btn/index.vue";
import FormInput from "@/shared/components/base/FormInput/index.vue";
import Modal from "@/shared/components/AppModal/Inner/index.vue";
import FilterGroup from "@/shared/components/base/FilterGroup/index.vue";
import {
  CommodityPriceTimeRangeEnum,
  type CommodityPrice,
  type CommodityPriceInput,
  type ShopCommodity,
} from "@/services/fyAdminApi";
import { useI18n } from "@/shared/composables/useI18n";
import { useForm } from "vee-validate";
import { useComlink } from "@/shared/composables/useComlink";
import { useShopCommodityPriceQueries } from "@/admin/composables/useShopCommodityPriceQueries";
import { CommodityPricePathEnum } from "@/services/fyApi";

const { t, l, toUEC } = useI18n();

type Props = {
  shopId: string;
  path: CommodityPricePathEnum;
  shopCommodity: ShopCommodity;
};

const props = defineProps<Props>();

const prices = computed(() => {
  if (props.path === "sell") {
    return sellPrices.value || [];
  }

  if (props.path === "buy") {
    return buyPrices.value || [];
  }

  return rentalPrices.value || [];
});

const initialValues = ref<CommodityPriceInput>({
  shopCommodityId: props.shopCommodity.id,
  price: undefined,
  timeRange: undefined,
  path: props.path,
});

const validationSchema = {
  price: "required",
  timeRange: props.path === "rental" ? "required" : undefined,
};

const { useFieldModel, handleSubmit } = useForm({
  initialValues,
  validationSchema,
});

const [price, timeRange] = useFieldModel(["price", "timeRange"]);

const comlink = useComlink();

const timeRanges = computed(() => {
  return Object.values(CommodityPriceTimeRangeEnum).map((value) => ({
    value,
    label: value,
  }));
});

const {
  createMutation,
  destroyMutation,
  buyPricesQuery,
  sellPricesQuery,
  rentalPricesQuery,
} = useShopCommodityPriceQueries(props.shopId, props.shopCommodity.id);

const { data: buyPrices } = buyPricesQuery({
  enabled: props.path === "buy",
});

const { data: sellPrices } = sellPricesQuery({
  enabled: props.path === "sell",
});

const { data: rentalPrices } = rentalPricesQuery({
  enabled: props.path === "rental",
});

const mutation = createMutation();

const onSubmit = handleSubmit(async (values) => {
  mutation.mutate(values, {
    onSuccess: () => {
      price.value = undefined;
      timeRange.value = undefined;
      comlink.emit("prices-update");
    },
  });
});

const title = computed(() => {
  return t(`headlines.modals.shopCommodity.${props.path}Prices`, {
    shopCommodity: props.shopCommodity.item?.name,
  });
});

const destroy = destroyMutation();

const handleDestroy = async (record: CommodityPrice) => {
  await destroy.mutate(record.id);

  comlink.emit("prices-update");
};
</script>

<script lang="ts">
export default {
  name: "BuyPricesModal",
};
</script>

<style lang="scss" scoped>
@import "index";
</style>
