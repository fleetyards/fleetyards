<template>
  <ValidationObserver v-slot="{ handleSubmit }" :small="true" :slim="true">
    <Modal v-if="form" :title="t('headlines.modals.commodityPrice.create')">
      <form id="price-submission-new" @submit.prevent="handleSubmit(create)">
        <p v-html="t('texts.commodityPrice.info')"></p>
        <div class="row">
          <div class="col">
            <ValidationProvider
              v-slot="{ errors }"
              vid="stationSlug"
              rules="required"
              :name="t('labels.commodityPrice.station')"
              :slim="true"
            >
              <CollectionFilterGroup
                v-model="internalStationSlug"
                :label="t('labels.filters.shopCommodities.station')"
                :collection="stationsCollection"
                :error="errors[0]"
                value-attr="slug"
                :collection-filter="stationsCollectionFilter"
                :paginated="true"
                :searchable="true"
                name="station"
              />
            </ValidationProvider>
          </div>
          <div class="col">
            <ValidationProvider
              v-slot="{ errors }"
              vid="shopId"
              rules="required"
              :name="t('labels.commodityPrice.shopId')"
              :slim="true"
            >
              <CollectionFilterGroup
                :key="`shop-select-${internalStationSlug}`"
                v-model="form.shopId"
                :label="t('labels.filters.shopCommodities.shopId')"
                :collection="shopsCollection"
                value-attr="id"
                :collection-filter="shopsCollectionFilter"
                :disabled="!internalStationSlug"
                :error="errors[0]"
                name="shopId"
                @loaded="setDefaultShopId"
              />
            </ValidationProvider>
          </div>
        </div>
        <hr class="slim-spacer space-bottom" />
        <div class="row">
          <div v-if="!commodityItemType" class="col">
            <ValidationProvider
              v-slot="{ errors }"
              vid="commodityItemType"
              rules="required"
              :name="t('labels.commodityPrice.commodityItemType')"
              :slim="true"
            >
              <CollectionFilterGroup
                v-model="form.commodityItemType"
                :label="t('labels.filters.shopCommodities.commodityType')"
                :collection="shopCommodityTypesCollection"
                :error="errors[0]"
                name="commodityItemType"
              />
            </ValidationProvider>
          </div>
          <div class="col">
            <ValidationProvider
              v-slot="{ errors }"
              vid="commodityItemId"
              rules="required"
              :name="t('labels.commodityPrice.commodityItemId')"
              :slim="true"
            >
              <CollectionFilterGroup
                v-if="
                  form.commodityItemType === 'Commodity' ||
                  !form.commodityItemType
                "
                key="commodity-filter-group"
                v-model="form.commodityItemId"
                :label="t('labels.filters.shopCommodities.commodity')"
                :collection="commoditiesCollection"
                name="equipment-commodityItemId"
                value-attr="id"
                :disabled="!form.commodityItemType"
                :error="errors[0]"
                :paginated="true"
                :searchable="true"
              />
              <CollectionFilterGroup
                v-if="form.commodityItemType === 'Component'"
                key="component-filter-group"
                v-model="form.commodityItemId"
                :label="t('labels.filters.shopCommodities.component')"
                :collection="componentsCollection"
                name="components-commodityItemId"
                value-attr="id"
                :error="errors[0]"
                :paginated="true"
                :searchable="true"
              />
              <CollectionFilterGroup
                v-if="form.commodityItemType === 'Equipment'"
                key="equipment-filter-group"
                v-model="form.commodityItemId"
                :label="t('labels.filters.shopCommodities.equipment')"
                :collection="equipmentCollection"
                name="equipment-commodityItemId"
                value-attr="id"
                :error="errors[0]"
                :paginated="true"
                :searchable="true"
              />
              <CollectionFilterGroup
                v-if="form.commodityItemType === 'Model'"
                key="model-filter-group"
                v-model="form.commodityItemId"
                :label="t('labels.filters.shopCommodities.model')"
                :collection="modelsCollection"
                name="models-commodityItemId"
                value-attr="id"
                :error="errors[0]"
                :paginated="true"
                :searchable="true"
              />
              <CollectionFilterGroup
                v-if="form.commodityItemType === 'ModelModule'"
                key="model-module-filter-group"
                v-model="form.commodityItemId"
                :label="t('labels.filters.shopCommodities.modelModule')"
                :collection="modelModulesCollection"
                name="modelModules-commodityItemId"
                value-attr="id"
                :error="errors[0]"
                :paginated="true"
                :searchable="true"
              />
              <CollectionFilterGroup
                v-if="form.commodityItemType === 'ModelPaint'"
                key="model-paint-filter-group"
                v-model="form.commodityItemId"
                :label="t('labels.filters.shopCommodities.modelPaint')"
                :collection="modelPaintsCollection"
                name="modelPaints-commodityItemId"
                value-attr="id"
                label-attr="nameWithModel"
                :error="errors[0]"
                :paginated="true"
                :searchable="true"
              />
            </ValidationProvider>
          </div>
        </div>
        <hr class="slim-spacer space-bottom" />
        <div class="row">
          <div class="col-12 col-md-6">
            <ValidationProvider
              v-slot="{ errors }"
              vid="path"
              rules="required"
              :name="t('labels.commodityPrice.type')"
              :slim="true"
            >
              <FilterGroup
                v-model="form.path"
                name="path"
                :error="errors[0]"
                :label="t('labels.commodityPrice.type')"
                :options="pathOptions"
              />
            </ValidationProvider>
          </div>
          <div class="col-12 col-md-6">
            <ValidationProvider
              v-slot="{ errors }"
              vid="price"
              rules="required|min_value:0.01"
              :name="t('labels.commodityPrice.price')"
              :slim="true"
            >
              <FormInput
                id="commodityPrice-price"
                v-model="form.price"
                translation-key="commodityPrice.price"
                :error="errors[0]"
                :label="t('labels.commodityPrice.price')"
                :step="0.01"
                :min="0.01"
                type="number"
                :suffix="t('labels.uec')"
              />
            </ValidationProvider>
          </div>
          <template v-if="form.path === 'rental'">
            <div class="col-md-6"></div>
            <div class="col-12 col-md-6">
              <ValidationProvider
                v-slot="{ errors }"
                vid="timeRange"
                rules="required"
                :name="t('labels.commodityPrice.timeRange')"
                :slim="true"
              >
                <CollectionFilterGroup
                  v-model="form.timeRange"
                  name="time-range"
                  :error="errors[0]"
                  :label="t('labels.filters.commodityPrice.timeRange')"
                  :collection="commodityPricesCollction"
                  collection-method="timeRanges"
                />
              </ValidationProvider>
            </div>
          </template>
        </div>
      </form>
      <template #footer>
        <div class="float-sm-right">
          <Btn
            form="price-submission-new"
            :loading="submitting"
            type="submit"
            size="large"
            :inline="true"
          >
            {{ t("actions.save") }}
          </Btn>
        </div>
      </template>
    </Modal>
  </ValidationObserver>
</template>

<script lang="ts" setup>
import Modal from "@/shared/components/AppModal/Inner/index.vue";
import Btn from "@/shared/components/base/Btn/index.vue";
import FormInput from "@/shared/components/base/FormInput/index.vue";
import FilterGroup from "@/shared/components/base/FilterGroup/index.vue";
import { useI18n } from "@/shared/composables/useI18n";
import { useNoty } from "@/shared/composables/useNoty";
import type { CommodityPriceInput, Shop } from "@/services/fyApi";
import { CommodityPricePathEnum } from "@/services/fyApi";
import { useComlink } from "@/shared/composables/useComlink";
import type { FilterGroupOption } from "@/shared/components/base/FilterGroup/Option/index.vue";

type Props = {
  shopId?: string;
  stationSlug?: string;
  shopTypes?: string[];
  commodityItemType?: string;
  pathOptions?: FilterGroupOption[];
};

const props = withDefaults(defineProps<Props>(), {
  shopId: undefined,
  stationSlug: undefined,
  shopTypes: undefined,
  commodityItemType: undefined,
  pathOptions: () => [],
});

const { t } = useI18n();

const { displayAlert, displaySuccess } = useNoty(t);

const submitting = ref(false);

const form = ref<CommodityPriceInput>({});

const internalStationSlug = ref<string | undefined>();

const stationsCollectionFilter = computed(() => {
  return {
    withShops: true,
    commodityItemType: props.commodityItemType,
  };
});

const shopsCollectionFilter = computed(() => {
  return {
    stationIn: [internalStationSlug.value],
    commodityItemType: props.commodityItemType,
  };
});

watch(
  () => internalStationSlug.value,
  (value) => {
    if (!value) {
      internalStationSlug.value = props.stationSlug;
    }

    form.value.shopId = props.shopId || undefined;
  },
);

watch(
  () => props.commodityItemType,
  () => {
    form.value.commodityItemType = props.commodityItemType;
    form.value.commodityItemId = undefined;
  },
);

watch(
  () => props.stationSlug,
  () => {
    internalStationSlug.value = props.stationSlug;
  },
);

onMounted(() => {
  internalStationSlug.value = props.stationSlug;

  form.value = {
    shopId: props.shopId,
    commodityItemId: undefined,
    path: CommodityPricePathEnum.SELL,
    timeRange: undefined,
    commodityItemType: props.commodityItemType,
    price: undefined,
  };
});

const comlink = useComlink();

const create = async () => {
  submitting.value = true;

  const newCommodityPrice = await commodityPricesCollction.create(this.form);

  submitting.value = false;

  if (!newCommodityPrice.error) {
    displaySuccess({
      text: t("messages.commodityPrice.create.success"),
    });
    comlink.emit("close-modal");
  } else {
    displayAlert({ text: newCommodityPrice.error.message });
  }
};

const setDefaultShopId = (shops: Shop[]) => {
  if (shops.length === 1) {
    form.value.shopId = shops[0].id;
  } else {
    form.value.shopId = undefined;
  }
};
</script>

<script lang="ts">
export default {
  name: "PricesModal",
};
</script>
