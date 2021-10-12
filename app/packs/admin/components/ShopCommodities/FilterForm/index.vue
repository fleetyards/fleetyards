<template>
  <form @submit.prevent="filter">
    <FormInput
      id="commodity-item-name"
      v-model="search"
      translation-key="filters.shopCommodities.name"
      :no-label="true"
      :clearable="true"
    />

    <CollectionFilterGroup
      key="component-item-type-filters-filter-group"
      v-model="form.component_item_type"
      :label="$t('labels.filters.shopCommodities.componentItemTypeFilter')"
      :collection="componentItemTypeFiltersCollection"
      name="component-item-type-filter"
      :searchable="true"
      :multiple="true"
      :no-label="true"
    />

    <CollectionFilterGroup
      key="equipment-item-type-filters-filter-group"
      v-model="form.equipment_item_type"
      :label="$t('labels.filters.shopCommodities.equipmentItemTypeFilter')"
      :collection="equipmentItemTypeFiltersCollection"
      name="equipment-item-type-filter"
      :searchable="true"
      :multiple="true"
      :no-label="true"
    />

    <CollectionFilterGroup
      key="equipment-type-filters-filter-group"
      v-model="form.equipment_type"
      :label="$t('labels.filters.shopCommodities.equipmentTypeFilter')"
      :collection="equipmentTypeFiltersCollection"
      name="equipment-type-filter"
      :searchable="true"
      :multiple="true"
      :no-label="true"
    />

    <CollectionFilterGroup
      key="equipment-slot-filters-filter-group"
      v-model="form.equipment_slot"
      :label="$t('labels.filters.shopCommodities.equipmentSlotFilter')"
      :collection="equipmentSlotFiltersCollection"
      name="equipment-slot-filter"
      :searchable="true"
      :multiple="true"
      :no-label="true"
    />

    <Btn
      :disabled="!isFilterSelected"
      :block="true"
      @click.native="resetFilter"
    >
      <i class="fal fa-times" />
      {{ $t('actions.resetFilter') }}
    </Btn>
  </form>
</template>

<script lang="ts">
import Vue from 'vue'
import { Component, Watch } from 'vue-property-decorator'
import CollectionFilterGroup from 'frontend/core/components/Form/CollectionFilterGroup'
import FormInput from 'frontend/core/components/Form/FormInput'
import Btn from 'frontend/core/components/Btn'
import componentItemTypeFiltersCollection from 'admin/api/collections/ComponentItemTypeFilters'
import equipmentItemTypeFiltersCollection from 'admin/api/collections/EquipmentItemTypeFilters'
import equipmentTypeFiltersCollection from 'admin/api/collections/EquipmentTypeFilters'
import equipmentSlotFiltersCollection from 'admin/api/collections/EquipmentSlotFilters'
import { debounce } from 'ts-debounce'
import { getFilters, isFilterSelected } from 'frontend/utils/Filters'

@Component<ShopCommoditiesFilterForm>({
  components: {
    CollectionFilterGroup,
    FormInput,
    Btn,
  },
})
export default class ShopCommoditiesFilterForm extends Vue {
  componentItemTypeFiltersCollection: ComponentItemTypeFiltersCollection = componentItemTypeFiltersCollection

  equipmentItemTypeFiltersCollection: EquipmentItemTypeFiltersCollection = equipmentItemTypeFiltersCollection

  equipmentTypeFiltersCollection: EquipmentTypeFiltersCollection = equipmentTypeFiltersCollection

  equipmentSlotFiltersCollection: EquipmentSlotFiltersCollection = equipmentSlotFiltersCollection

  loading: boolean = false

  search: string = null

  form = {
    component_item_type: [],
    equipment_item_type: [],
    equipment_type: [],
    equipment_slot: [],
  }

  filter: Function = debounce(this.debouncedFilter, 500)

  get isFilterSelected() {
    return isFilterSelected(this.$route.query.filters)
  }

  @Watch('form', {
    deep: true,
  })
  onFormChange() {
    this.filter()
  }

  @Watch('search')
  onSearchChange() {
    this.filter()
  }

  resetFilter() {
    this.$router
      .replace({
        name: this.$route.name || undefined,
        query: {},
      })
      // eslint-disable-next-line @typescript-eslint/no-empty-function
      .catch(_err => {})
  }

  debouncedFilter() {
    this.$router
      .replace({
        name: this.$route.name || undefined,
        query: {
          ...this.$route.query,
          search: this.search || undefined,
          filters: getFilters(this.form),
        },
      })
      // eslint-disable-next-line @typescript-eslint/no-empty-function
      .catch(_err => {})
  }

  mounted() {
    this.setupForm()
  }

  @Watch('$route')
  onRouteChange() {
    this.setupForm()
  }

  setupForm() {
    const filters = this.$route.query.filters || {}
    this.form = {
      component_item_type: filters.component_item_type || [],
      equipment_item_type: filters.equipment_item_type || [],
      equipment_type: filters.equipment_type || [],
      equipment_slot: filters.equipment_slot || [],
    }
  }
}
</script>
