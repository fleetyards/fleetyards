<template>
  <ValidationObserver v-slot="{ handleSubmit }" :small="true" :slim="true">
    <Modal v-if="shopCommodity" ref="modal" :title="title" class="prices-modal">
      <form @submit.prevent="handleSubmit(create)">
        <div
          v-for="record in collection.records"
          :key="record.id"
          class="price-item"
        >
          <FormInput
            :id="record.id"
            class="input"
            type="number"
            :disabled="true"
            :value="record.price"
            :no-label="true"
          />
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
          <Btn size="small" @click.native="destroy(record)">
            <i class="fa fa-times" />
          </Btn>
        </div>
        <div v-if="form" class="new-price">
          <ValidationProvider
            v-slot="{ errors }"
            vid="price"
            rules="required"
            :name="t('labels.price')"
            :slim="true"
          >
            <FormInput
              id="new-price"
              v-model="form.price"
              :error="errors[0]"
              class="input"
              type="number"
              :no-label="true"
              :autofocus="true"
              translation-key="commodityPrice.price"
            />
          </ValidationProvider>
          <ValidationProvider
            v-if="path === 'rental'"
            v-slot="{ errors }"
            vid="timeRange"
            rules="required"
            :name="t('labels.commodityPrice.timeRange')"
            :slim="true"
          >
            <FilterGroup
              v-model="form.timeRange"
              name="time-range"
              :error="errors[0]"
              :label="t('labels.filters.commodityPrice.timeRange')"
              :collection="collection"
              collection-method="timeRanges"
              :no-label="true"
            />
          </ValidationProvider>
          <Btn size="small" @click="handleSubmit(create)">
            <i class="fa fa-check" />
          </Btn>
        </div>
      </form>
    </Modal>
  </ValidationObserver>
</template>

<script lang="ts" setup>
// import commodityPricesCollection from "@/admin/api/collections/CommodityPrices";
import Btn from "@/shared/components/base/Btn/index.vue";
import FormInput from "@/shared/components/base/FormInput/index.vue";
import Modal from "@/shared/components/AppModal/Inner/index.vue";
import FilterGroup from "@/shared/components/base/FilterGroup/index.vue";
import type { ShopCommodity } from "@/services/fyAdminApi";
import { useI18n} from "@/shared/composables/useI18n"

const { t, l } = useI18n();

type Props = {
  shopId: string;
  path: string;
  shopCommodity: ShopCommodity;
}

const props = defineProps<Props>();

  // collection: CommodityPricesCollection = commodityPricesCollection;

  // prices: ShopCommodityPrice[] = [];

  const form = ref<ShopCommodityPriceForm>({]});

  const title = computed(() => {
    return t(`headlines.modals.shopCommodity.${props.path}Prices`, {
      shopCommodity: props.shopCommodity.item?.name,
    });
  })

  const params = computed(() => {
    return {
      shopId: props.shopId,
      shopCommodityId: props.shopCommodity.id,
      path: props.path
    };
  })

  onMounted(() => {
    // fetch();
    setupForm();
  })

  const setupForm = () => {
    form.value = {
      shopCommodityId: props.shopCommodity.id,
      path: props.path,
      price: null,
    };
  }

  // const fetch =  async () => {
  //   await this.collection.findAll(this.params);
  // }

  // const create = async () => {
  //   await this.collection.create(this.form);

  //   this.$comlink.$emit("prices-update");

  //   this.newPrice = null;

  //   this.$comlink.$emit("close-modal");
  // }

  // const destroy =  async (record) => {
  //   await this.collection.destroy(record.id);

  //   this.$comlink.$emit("prices-update");

  //   this.fetch();
  // }
</script>

<script lang="ts">
export default {
  name: "BuyPricesModal",
};
</script>
