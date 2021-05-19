<template>
  <ValidationObserver v-slot="{ handleSubmit }" :small="true" :slim="true">
    <Modal v-if="form" :title="$t('headlines.modals.commodityPrice.create')">
      <form
        :id="`price-submission-${id}`"
        @submit.prevent="handleSubmit(create)"
      >
        <p v-html="$t('texts.commodityPrice.info')"></p>
        <div class="row">
          <div class="col">
            <ValidationProvider
              v-slot="{ errors }"
              vid="stationSlug"
              rules="required"
              :name="$t('labels.commodityPrice.station')"
              :slim="true"
            >
              <CollectionFilterGroup
                v-model="internalStationSlug"
                :label="$t('labels.filters.shopCommodities.station')"
                :collection="stationsCollection"
                :error="errors[0]"
                value-attr="slug"
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
              :name="$t('labels.commodityPrice.shopId')"
              :slim="true"
            >
              <CollectionFilterGroup
                :key="`shop-select-${internalStationSlug}`"
                v-model="form.shopId"
                :label="$t('labels.filters.shopCommodities.shopId')"
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
              :name="$t('labels.commodityPrice.commodityItemType')"
              :slim="true"
            >
              <CollectionFilterGroup
                v-model="form.commodityItemType"
                :label="$t('labels.filters.shopCommodities.commodityType')"
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
              :name="$t('labels.commodityPrice.commodityItemId')"
              :slim="true"
            >
              <CollectionFilterGroup
                v-if="
                  form.commodityItemType === 'Commodity' ||
                    !form.commodityItemType
                "
                key="commodity-filter-group"
                v-model="form.commodityItemId"
                :label="$t('labels.filters.shopCommodities.commodity')"
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
                :label="$t('labels.filters.shopCommodities.component')"
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
                :label="$t('labels.filters.shopCommodities.equipment')"
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
                :label="$t('labels.filters.shopCommodities.model')"
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
                :label="$t('labels.filters.shopCommodities.modelModule')"
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
                :label="$t('labels.filters.shopCommodities.modelPaint')"
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
              :name="$t('labels.commodityPrice.type')"
              :slim="true"
            >
              <FilterGroup
                v-model="form.path"
                name="path"
                :error="errors[0]"
                :label="$t('labels.commodityPrice.type')"
                :options="pathOptions"
              />
            </ValidationProvider>
          </div>
          <div class="col-12 col-md-6">
            <ValidationProvider
              v-slot="{ errors }"
              vid="price"
              rules="required|min_value:0.01"
              :name="$t('labels.commodityPrice.price')"
              :slim="true"
            >
              <FormInput
                id="commodityPrice-price"
                v-model="form.price"
                translation-key="commodityPrice.price"
                :error="errors[0]"
                :label="$t('labels.commodityPrice.price')"
                step="0.01"
                min="0.01"
                type="number"
                :suffix="$t('labels.uec')"
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
                :name="$t('labels.commodityPrice.timeRange')"
                :slim="true"
              >
                <CollectionFilterGroup
                  v-model="form.timeRange"
                  name="time-range"
                  :error="errors[0]"
                  :label="$t('labels.filters.commodityPrice.timeRange')"
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
            :form="`price-submission-${id}`"
            :loading="submitting"
            type="submit"
            size="large"
            :inline="true"
          >
            {{ $t('actions.save') }}
          </Btn>
        </div>
      </template>
    </Modal>
  </ValidationObserver>
</template>

<script lang="ts">
import Vue from 'vue'
import { Component, Prop, Watch } from 'vue-property-decorator'
import Modal from 'frontend/core/components/AppModal/Modal'
import Btn from 'frontend/core/components/Btn'
import FormInput from 'frontend/core/components/Form/FormInput'
import CollectionFilterGroup from 'frontend/core/components/Form/CollectionFilterGroup'
import FilterGroup from 'frontend/core/components/Form/FilterGroup'
import { displayAlert, displaySuccess } from 'frontend/lib/Noty'
import stationsCollection from 'frontend/api/collections/Stations'
import shopsCollection from 'frontend/api/collections/Shops'
import shopCommodityTypesCollection from 'frontend/api/collections/ShopCommodityTypes'
import modelsCollection from 'frontend/api/collections/Models'
import modelModulesCollection from 'frontend/api/collections/ModelModules'
import modelPaintsCollection from 'frontend/api/collections/ModelPaints'
import commoditiesCollection from 'frontend/api/collections/Commodities'
import componentsCollection from 'frontend/api/collections/Components'
import equipmentCollection from 'frontend/api/collections/Equipment'
import commodityPricesCollction from 'frontend/api/collections/CommodityPrices'

@Component<GroupModal>({
  components: {
    Modal,
    Btn,
    FormInput,
    CollectionFilterGroup,
    FilterGroup,
  },
})
export default class PricesModal extends Vue {
  @Prop({ default: null }) shopId!: string

  @Prop({ default: null }) stationSlug!: string

  @Prop({ default: null }) commodityItemType!: string

  @Prop({ default: [] }) pathOptions!: FilterGroupItem[]

  submitting: boolean = false

  form: CommodityPriceForm | null = null

  stationsCollection: StationsCollection = stationsCollection

  shopsCollection: shopsCollection = shopsCollection

  shopCommodityTypesCollection: ShopCommodityTypesCollection = shopCommodityTypesCollection

  modelsCollection: ModelsCollection = modelsCollection

  modelModulesCollection: ModelModulesCollection = modelModulesCollection

  modelPaintsCollection: ModelPaintsCollection = modelPaintsCollection

  commoditiesCollection: CommoditiesCollection = commoditiesCollection

  componentsCollection: ComponentsCollection = componentsCollection

  equipmentCollection: EquipmentCollection = equipmentCollection

  commodityPricesCollction: CommodityPricesCollction = commodityPricesCollction

  internalStationSlug: string = null

  get shopsCollectionFilter() {
    return {
      stationIn: [this.internalStationSlug],
    }
  }

  get id() {
    return (this.hangarGroup && this.hangarGroup.id) || 'new'
  }

  @Watch('internalStationSlug')
  onInternalStationSlugChange(value) {
    if (!value) {
      this.internalStationSlug = this.stationSlug
    }

    this.form.shopId = this.shopId || null
  }

  @Watch('form.commodityItemType')
  onFormCommodityTypeChange() {
    this.form.commodityItemId = null
  }

  @Watch('commodityItemType')
  onCommodityTypeChange() {
    this.form.commodityItemType = this.commodityItemType
  }

  @Watch('staationSlug')
  onStationSlugChange() {
    this.internalStationSlug = this.stationSlug
  }

  mounted() {
    this.internalStationSlug = this.stationSlug

    this.form = {
      shopId: this.shopId,
      commodityItemId: null,
      path: 'sell',
      timeRange: null,
      commodityItemType: this.commodityItemType,
      price: null,
    }
  }

  async create() {
    this.submitting = true

    const newCommodityPrice = await commodityPricesCollction.create(this.form)

    this.submitting = false

    if (!newCommodityPrice.error) {
      displaySuccess({
        text: this.$t('messages.commodityPrice.create.success'),
      })
      this.$comlink.$emit('close-modal')
    } else {
      displayAlert({ text: newCommodityPrice.error.message })
    }
  }

  setDefaultShopId(shops) {
    if (shops.length === 1) {
      this.form.shopId = shops[0].id
    } else {
      this.form.shopId = null
    }
  }
}
</script>
