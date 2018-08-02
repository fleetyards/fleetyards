<template>
  <form @submit.prevent="filter">
    <div class="form-group">
      <label for="filter-model-name-or-description">
        {{ t('labels.filters.models.nameOrDescription') }}
      </label>
      <input
        id="filter-model-name-or-description"
        v-model="form.nameOrDescriptionCont"
        :placeholder="t('placeholders.filters.models.nameOrDescription')"
        type="text"
        class="form-control"
      >
      <a
        v-if="form.nameOrDescriptionCont"
        class="btn btn-clear"
        @click="clearNameOrDescription"
        v-html="'&times;'"
      />
    </div>
    <FilterGroup
      v-if="manufacturerOptions.length > 0"
      :options="manufacturerOptions"
      v-model="form.manufacturerSlugIn"
      :label="t('labels.filters.models.manufacturer')"
      multiple
    />
    <FilterGroup
      v-if="productionStatusOptions.length > 0"
      :options="productionStatusOptions"
      v-model="form.productionStatusIn"
      :label="t('labels.filters.models.productionStatus')"
      multiple
    />
    <FilterGroup
      v-if="classificationOptions.length > 0"
      :options="classificationOptions"
      v-model="form.classificationIn"
      :label="t('labels.filters.models.classification')"
      multiple
    />
    <FilterGroup
      v-if="focusOptions.length > 0"
      :options="focusOptions"
      v-model="form.focusIn"
      :label="t('labels.filters.models.focus')"
      multiple
    />
    <FilterGroup
      v-if="sizeOptions.length > 0"
      :options="sizeOptions"
      v-model="form.sizeIn"
      :label="t('labels.filters.models.size')"
      multiple
    />
    <FilterGroup
      :options="priceOptions"
      v-model="form.priceIn"
      :label="t('labels.filters.models.price')"
      multiple
    />
    <RadioList
      :label="t('labels.filters.models.onSale')"
      :reset-label="t('labels.all')"
      :options="booleanOptions"
      v-model="form.onSaleEq"
      name="onSaleEq"
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
  },
  data() {
    const query = this.$route.query.q || {}
    return {
      loading: false,
      form: {
        nameOrDescriptionCont: query.nameOrDescriptionCont,
        onSaleEq: query.onSaleEq,
        manufacturerSlugIn: query.manufacturerSlugIn || [],
        classificationIn: query.classificationIn || [],
        focusIn: query.focusIn || [],
        productionStatusIn: query.productionStatusIn || [],
        priceIn: query.priceIn || [],
        sizeIn: query.sizeIn || [],
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
      sizeOptions: [],
      priceOptions: [
        {
          value: '-25',
          name: '< $25',
        }, {
          value: '25-50',
          name: '$25 - $49',
        }, {
          value: '50-75',
          name: '$50 - $74',
        }, {
          value: '75-100',
          name: '$75 - $99',
        }, {
          value: '100-150',
          name: '$100 - $149',
        }, {
          value: '150-200',
          name: '$150 - $199',
        }, {
          value: '200-350',
          name: '$200 - $349',
        }, {
          value: '350-500',
          name: '$350 - $499',
        }, {
          value: '500-1000',
          name: '$500 - $999',
        }, {
          value: '1000-',
          name: '> $1000',
        },
      ],
    }
  },
  watch: {
    $route() {
      const query = this.$route.query.q || {}
      this.form = {
        nameOrDescriptionCont: query.nameOrDescriptionCont,
        onSaleEq: query.onSaleEq,
        manufacturerSlugIn: query.manufacturerSlugIn || [],
        classificationIn: query.classificationIn || [],
        focusIn: query.focusIn || [],
        productionStatusIn: query.productionStatusIn || [],
        priceIn: query.priceIn || [],
        sizeIn: query.sizeIn || [],
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
    clearNameOrDescription() {
      this.form.nameOrDescriptionCont = null
    },
    clearOnSale() {
      this.form.onSaleEq = null
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
          this.sizeOptions = args.data.filter(item => item.category === 'size')
        }
      })
    },
  },
}
</script>
