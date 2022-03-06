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

<script>
import debounce from 'lodash.debounce'
import CollectionFilterGroup from '@/frontend/core/components/Form/CollectionFilterGroup/index.vue'
import FormInput from '@/frontend/core/components/Form/FormInput/index.vue'
import Btn from '@/frontend/core/components/Btn/index.vue'
import componentItemTypeFiltersCollection from '@/admin/api/collections/ComponentItemTypeFilters'
import equipmentItemTypeFiltersCollection from '@/admin/api/collections/EquipmentItemTypeFilters'
import equipmentTypeFiltersCollection from '@/admin/api/collections/EquipmentTypeFilters'
import equipmentSlotFiltersCollection from '@/admin/api/collections/EquipmentSlotFilters'
import { getFilters, isFilterSelected } from '@/frontend/utils/Filters'

export default {
  name: 'ShopCommoditiesFilterForm',
  components: {
    Btn,
    CollectionFilterGroup,
    FormInput,
  },

  data() {
    return {
      componentItemTypeFiltersCollection: componentItemTypeFiltersCollection,
      equipmentItemTypeFiltersCollection: equipmentItemTypeFiltersCollection,
      equipmentSlotFiltersCollection: equipmentSlotFiltersCollection,
      equipmentTypeFiltersCollection: equipmentTypeFiltersCollection,
      filter: debounce(this.debouncedFilter, 500),
      form: {
        component_item_type: [],
        equipment_item_type: [],
        equipment_slot: [],
        equipment_type: [],
      },
      loading: false,
      search: null,
    }
  },

  computed: {
    isFilterSelected() {
      return isFilterSelected(this.$route.query.filters)
    },
  },

  watch: {
    $route() {
      this.setupForm()
    },

    form: {
      deep: true,
      handler() {
        this.filter()
      },
    },

    search() {
      this.filter()
    },
  },

  mounted() {
    this.setupForm()
  },

  methods: {
    debouncedFilter() {
      this.$router
        .replace({
          name: this.$route.name || undefined,
          query: {
            ...this.$route.query,
            filters: getFilters(this.form),
            search: this.search || undefined,
          },
        })
        .catch((_err) => {})
    },

    resetFilter() {
      this.$router
        .replace({
          name: this.$route.name || undefined,
          query: {},
        })
        .catch((_err) => {})
    },

    setupForm() {
      const filters = this.$route.query.filters || {}
      this.form = {
        component_item_type: filters.component_item_type || [],
        equipment_item_type: filters.equipment_item_type || [],
        equipment_slot: filters.equipment_slot || [],
        equipment_type: filters.equipment_type || [],
      }
    },
  },
}
</script>
