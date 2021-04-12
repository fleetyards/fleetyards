<template>
  <form @submit.prevent="filter">
    <FormInput
      id="commodity-item-name"
      v-model="form.nameCont"
      translation-key="filters.shopCommodities.name"
      :no-label="true"
      :clearable="true"
    />

    <CollectionFilterGroup
      key="component-item-type-filters-filter-group"
      v-model="form.componentItemTypeIn"
      :label="$t('labels.filters.shopCommodities.componentItemTypeFilter')"
      :collection="componentItemTypeFiltersCollection"
      name="component-item-type-filter"
      :searchable="true"
      :multiple="true"
      :no-label="true"
    />

    <CollectionFilterGroup
      key="equipment-item-type-filters-filter-group"
      v-model="form.equipmentItemTypeIn"
      :label="$t('labels.filters.shopCommodities.equipmentItemTypeFilter')"
      :collection="equipmentItemTypeFiltersCollection"
      name="equipment-item-type-filter"
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
import Filters from 'frontend/mixins/Filters'
import CollectionFilterGroup from 'frontend/core/components/Form/CollectionFilterGroup'
import FormInput from 'frontend/core/components/Form/FormInput'
import Btn from 'frontend/core/components/Btn'
import componentItemTypeFiltersCollection from 'admin/api/collections/ComponentItemTypeFilters'
import equipmentItemTypeFiltersCollection from 'admin/api/collections/EquipmentItemTypeFilters'

@Component<ShopCommoditiesFilterForm>({
  components: {
    CollectionFilterGroup,
    FormInput,
    Btn,
  },
  mixins: [Filters],
})
export default class ShopCommoditiesFilterForm extends Vue {
  componentItemTypeFiltersCollection: ComponentItemTypeFiltersCollection = componentItemTypeFiltersCollection

  equipmentItemTypeFiltersCollection: EquipmentItemTypeFiltersCollection = equipmentItemTypeFiltersCollection

  loading: boolean = false

  form = {
    nameCont: null,
    componentItemTypeIn: [],
    equipmentItemTypeIn: [],
  }

  mounted() {
    this.setupForm()
  }

  @Watch('$route')
  onRouteChange() {
    this.setupForm()
  }

  setupForm() {
    const query = this.$route.query.q || {}
    this.form = {
      nameCont: query.nameCont,
      componentItemTypeIn: query.componentItemTypeIn || [],
      equipmentItemTypeIn: query.equipmentItemTypeIn || [],
    }
  }
}
</script>
