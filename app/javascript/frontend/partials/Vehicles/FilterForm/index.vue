<template>
  <form @submit.prevent="filter">
    <div class="form-group">
      <label :for="idFor('user-vehicle-name')">
        {{ t('labels.filters.vehicles.name') }}
      </label>
      <input
        :id="idFor('user-vehicle-name')"
        v-model="form.nameCont"
        :placeholder="t('placeholders.filters.vehicles.name')"
        type="text"
        class="form-control"
      >
      <a
        v-if="form.nameCont"
        class="btn btn-clear"
        @click="clearName"
        v-html="'&times;'"/>
    </div>
    <div class="form-group">
      <label :for="idFor('model-name-or-description')">
        {{ t('labels.filters.models.nameOrDescription') }}
      </label>
      <input
        :id="idFor('model-name-or-description')"
        v-model="form.modelNameOrModelDescriptionCont"
        :placeholder="t('placeholders.filters.models.nameOrDescription')"
        type="text"
        class="form-control"
      >
      <a
        v-if="form.modelNameOrModelDescriptionCont"
        class="btn btn-clear"
        @click="clearModelNameOrDescription"
        v-html="'&times;'"/>
    </div>
    <FilterGroup
      v-if="manufacturerOptions.length > 0"
      :options="manufacturerOptions"
      v-model="form.modelManufacturerSlugIn"
      :label="t('labels.filters.models.manufacturer')"
      :name="`${prefix}-manufacturer`"
      multiple
    />
    <FilterGroup
      v-if="productionStatusOptions.length > 0"
      :options="productionStatusOptions"
      v-model="form.modelProductionStatusIn"
      :label="t('labels.filters.models.productionStatus')"
      :name="`${prefix}-production-status`"
      multiple
    />
    <FilterGroup
      v-if="classificationOptions.length > 0"
      :options="classificationOptions"
      v-model="form.modelClassificationIn"
      :label="t('labels.filters.models.classification')"
      :name="`${prefix}-classification`"
      multiple
    />
    <FilterGroup
      v-if="focusOptions.length > 0"
      :options="focusOptions"
      v-model="form.modelFocusIn"
      :label="t('labels.filters.models.focus')"
      :name="`${prefix}-focus`"
      multiple
    />
    <FilterGroup
      v-if="hangarGroupsOptions.length > 0"
      :options="hangarGroupsOptions.map(item => {
        return {
          value: item.slug,
          name: item.name,
        }
      })"
      v-model="form.hangarGroupsSlugIn"
      :label="t('labels.filters.vehicles.group')"
      :name="`${prefix}-hangar-group`"
      multiple
    />
    <RadioList
      v-if="$route.name === 'hangar'"
      :label="t('labels.filters.vehicles.purchased')"
      :reset-label="t('labels.all')"
      :options="booleanOptions"
      v-model="form.purchasedEq"
      :name="`${prefix}-purchased`"
    />
    <RadioList
      :label="t('labels.filters.models.onSale')"
      :reset-label="t('labels.all')"
      :options="booleanOptions"
      v-model="form.modelOnSaleEq"
      :name="`${prefix}-sale`"
    />
    <Btn
      v-if="!hideButtons"
      :disabled="!isFilterSelected"
      block
      @click.native="reset"
    >
      <i class="fal fa-times" />
      {{ t('actions.resetFilter') }}
    </Btn>
    <Loader v-if="loading" />
  </form>
</template>

<script>
import I18n from 'frontend/mixins/I18n'
import Filters from 'frontend/mixins/Filters'
import RadioList from 'frontend/components/Form/RadioList'
import FilterGroup from 'frontend/components/Form/FilterGroup'
import Loader from 'frontend/components/Loader'
import Btn from 'frontend/components/Btn'

export default {
  components: {
    RadioList,
    FilterGroup,
    Loader,
    Btn,
  },
  mixins: [I18n, Filters],
  props: {
    hideButtons: {
      type: Boolean,
      default: false,
    },
    hangarGroupsOptions: {
      type: Array,
      default() {
        return []
      },
    },
    prefix: {
      type: String,
      default: 'filter',
    },
  },
  data() {
    const query = this.$route.query.q || {}
    return {
      form: {
        nameCont: query.nameCont,
        modelNameOrModelDescriptionCont: query.modelNameOrModelDescriptionCont,
        modelOnSaleEq: query.modelOnSaleEq,
        purchasedEq: query.purchasedEq,
        modelManufacturerSlugIn: query.modelManufacturerSlugIn || [],
        modelClassificationIn: query.modelClassificationIn || [],
        modelFocusIn: query.modelFocusIn || [],
        modelProductionStatusIn: query.modelProductionStatusIn || [],
        hangarGroupsSlugIn: query.hangarGroupsSlugIn || [],
      },
      booleanOptions: [{
        name: 'No',
        value: 'false',
      }, {
        name: 'Yes',
        value: 'true',
      }],
      manufacturerOptions: [],
      classificationOptions: [],
      focusOptions: [],
      productionStatusOptions: [],
    }
  },
  watch: {
    $route() {
      const query = this.$route.query.q || {}
      this.form = {
        nameCont: query.nameCont,
        modelNameOrModelDescriptionCont: query.modelNameOrModelDescriptionCont,
        modelOnSaleEq: query.modelOnSaleEq,
        purchasedEq: query.purchasedEq,
        modelManufacturerSlugIn: query.modelManufacturerSlugIn || [],
        modelClassificationIn: query.modelClassificationIn || [],
        modelFocusIn: query.modelFocusIn || [],
        modelProductionStatusIn: query.modelProductionStatusIn || [],
        hangarGroupsSlugIn: query.hangarGroupsSlugIn || [],
      }
      this.$store.commit('setFilters', { [this.$route.name]: this.form })
    },
    form: {
      handler() {
        this.filter()
      },
      deep: true,
    },
  },
  created() {
    this.fetch()
  },
  methods: {
    clearName() {
      this.form.nameCont = null
    },
    clearModelNameOrDescription() {
      this.form.modelNameOrModelDescriptionCont = null
    },
    filter() {
      const query = JSON.parse(JSON.stringify(this.form))
      Object.keys(query)
        .filter(key => !query[key] || query[key].length === 0)
        .forEach(key => delete query[key])
      this.$router.replace({
        name: this.$route.name,
        query: {
          q: query,
        },
      })
    },
    fetch() {
      this.loading = true
      this.$api.get('models/filters', {}, (args) => {
        this.loading = false
        if (!args.error) {
          this.manufacturerOptions = args.data.filter(item => item.category === 'manufacturer')
          this.classificationOptions = args.data.filter(item => item.category === 'classification')
          this.focusOptions = args.data.filter(item => item.category === 'focus')
          this.productionStatusOptions = args.data.filter(item => item.category === 'productionStatus')
        }
      })
    },
  },
}
</script>
