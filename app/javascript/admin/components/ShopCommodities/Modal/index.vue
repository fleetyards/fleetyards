<template>
  <ValidationObserver v-slot="{ handleSubmit }" :small="true" :slim="true">
    <Modal v-if="form" :title="title">
      <form :id="formId" @submit.prevent="handleSubmit(submit)">
        <div class="row">
          <div class="col-12 col-md-6">
            <div class="form-group">
              <ValidationProvider
                v-slot="{ errors }"
                vid="commodityItemType"
                rules="required"
                :name="$t('labels.shopCommodity.commodityItemType')"
                :slim="true"
              >
                <FilterGroup
                  v-model="form.commodityItemType"
                  :options="commodityTypeOptions"
                  :error="errors[0]"
                  name="commodityItemType"
                  :no-label="true"
                />
              </ValidationProvider>
            </div>
          </div>
          <div class="col-12 col-md-6">
            <div class="form-group">
              <CollectionFilterGroup
                v-if="form.commodityItemType === 'Component'"
                key="component-item-type-filters-filter-group"
                v-model="componentItemTypeFilter"
                :label="
                  $t('labels.filters.shopCommodities.componentItemTypeFilter')
                "
                :collection="componentItemTypeFiltersCollection"
                name="component-item-type-filter"
                :searchable="true"
                :no-label="true"
              />
            </div>
          </div>
          <div class="col-12">
            <div class="form-group">
              <ValidationProvider
                v-slot="{ errors }"
                vid="commodityItemId"
                rules="required"
                :name="$t('labels.shopCommodity.commodityItemId')"
                :slim="true"
              >
                <CollectionFilterGroup
                  v-if="form.commodityItemType === 'Commodity'"
                  key="commodity-filter-group"
                  v-model="form.commodityItemId"
                  :label="$t('labels.filters.shopCommodities.commodity')"
                  :collection="commoditiesCollection"
                  name="equipment-commodityItemId"
                  value-attr="id"
                  :error="errors[0]"
                  :paginated="true"
                  :searchable="true"
                  :no-label="true"
                />
                <CollectionFilterGroup
                  v-if="form.commodityItemType === 'Component'"
                  key="component-filter-group"
                  v-model="form.commodityItemId"
                  :label="$t('labels.filters.shopCommodities.component')"
                  :collection="componentsCollection"
                  :collection-filter="{
                    itemTypeEq: componentItemTypeFilter,
                  }"
                  name="components-commodityItemId"
                  value-attr="id"
                  :error="errors[0]"
                  :paginated="true"
                  :searchable="true"
                  :no-label="true"
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
                  :no-label="true"
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
                  :no-label="true"
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
                  :no-label="true"
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
                  :no-label="true"
                />
              </ValidationProvider>
            </div>
          </div>
        </div>
      </form>

      <template #footer>
        <div class="float-sm-right">
          <Btn
            :form="formId"
            :loading="submitting"
            type="submit"
            size="large"
            data-test="shopCommodity-save"
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
import FilterGroup from 'frontend/core/components/Form/FilterGroup'
import CollectionFilterGroup from 'frontend/core/components/Form/CollectionFilterGroup'
import Btn from 'frontend/core/components/Btn'
import shopCommodityCollection from 'admin/api/collections/ShopCommodities'
import modelsCollection from 'admin/api/collections/Models'
import commoditiesCollection from 'admin/api/collections/Commodities'
import componentsCollection from 'admin/api/collections/Components'
import equipmentCollection from 'admin/api/collections/Equipment'
import modelModulesCollection from 'admin/api/collections/ModelModules'
import modelPaintsCollection from 'admin/api/collections/ModelPaints'
import componentItemTypeFiltersCollection from 'admin/api/collections/ComponentItemTypeFilters'

@Component<VehicleModal>({
  components: {
    Modal,
    FilterGroup,
    CollectionFilterGroup,
    Btn,
  },
})
export default class VehicleModal extends Vue {
  @Prop({ required: true }) shopId: string

  @Prop({ default: null }) commodityItemType: string

  @Prop({ default: null }) shopCommodity: ShopCommodity

  modelsCollection: ModelsCollection = modelsCollection

  commoditiesCollection: CommoditiesCollection = commoditiesCollection

  componentsCollection: ComponentsCollection = componentsCollection

  equipmentCollection: EquipmentCollection = equipmentCollection

  modelModulesCollection: ModelModulesCollection = modelModulesCollection

  modelPaintsCollection: ModelPaintsCollection = modelPaintsCollection

  componentItemTypeFiltersCollection: ComponentItemTypeFiltersCollection = componentItemTypeFiltersCollection

  submitting: boolean = false

  componentItemTypeFilter: string | null = null

  form: Object | null = null

  commodityTypeOptions: FilterGroupItem[] = [
    {
      value: 'Commodity',
      name: 'Commodity',
    },
    {
      value: 'Component',
      name: 'Component',
    },
    {
      value: 'Equipment',
      name: 'Equipment',
    },
    {
      value: 'Model',
      name: 'Model',
    },
    {
      value: 'ModelModule',
      name: 'Model Module',
    },
    {
      value: 'ModelPaint',
      name: 'Model Paint',
    },
  ]

  get formId() {
    if (this.shopCommodity) {
      return `shopCommodity-${this.shopCommodity.id}`
    }

    return 'shopCommodity-new'
  }

  get title() {
    if (this.shopCommodity && this.shopCommodity.id) {
      return this.$t('headlines.modals.shopCommodity.update', {
        shopCommodity: this.shopCommodity.item.name,
      })
    }

    return this.$t('headlines.modals.shopCommodity.create')
  }

  mounted() {
    this.setupForm()
  }

  @Watch('shopCommodity')
  onShopCommodityChange() {
    this.setupForm()
  }

  fetchSubCategories() {
    return this.$api.get('filters/shop-commodities/sub-categories')
  }

  setupForm() {
    this.form = {
      commodityItemId: this.shopCommodity?.commodityItemId,
      commodityItemType:
        this.shopCommodity?.commodityItemType || this.commodityItemType,
    }
  }

  submit() {
    if (this.shopCommodity && this.shopCommodity.id) {
      this.update()
    } else {
      this.create()
    }
  }

  async create() {
    this.submitting = true

    if (await shopCommodityCollection.create(this.shopId, this.form, true)) {
      this.$comlink.$emit('close-modal')
    }

    this.submitting = false
  }

  async update() {
    this.submitting = true

    if (
      await shopCommodityCollection.update(
        this.shopCommodity.shopId,
        this.shopCommodity.id,
        this.form,
      )
    ) {
      this.$comlink.$emit('close-modal')
    }

    this.submitting = false
  }
}
</script>
