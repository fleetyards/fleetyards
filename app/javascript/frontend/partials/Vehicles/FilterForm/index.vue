<template>
  <form @submit.prevent="filter">
    <FormInput
      v-model="form.nameCont"
      :placeholder="$t('placeholders.filters.vehicles.name')"
      :aria-label="$t('placeholders.filters.vehicles.name')"
    />

    <FilterGroup
      v-model="form.manufacturerIn"
      :label="$t('labels.filters.models.manufacturer')"
      fetch-path="manufacturers/with-models"
      name="manufacturer"
      value-attr="slug"
      icon-attr="logo"
      paginated
      searchable
      multiple
    />

    <FilterGroup
      v-model="form.productionStatusIn"
      :label="$t('labels.filters.models.productionStatus')"
      fetch-path="models/production-states"
      name="production-status"
      multiple
    />

    <FilterGroup
      v-model="form.classificationIn"
      :label="$t('labels.filters.models.classification')"
      fetch-path="models/classifications"
      name="classification"
      searchable
      multiple
    />

    <FilterGroup
      v-model="form.focusIn"
      :label="$t('labels.filters.models.focus')"
      fetch-path="models/focus"
      name="focus"
      searchable
      multiple
    />

    <FilterGroup
      v-model="form.sizeIn"
      :label="$t('labels.filters.models.size')"
      fetch-path="models/sizes"
      name="size"
      multiple
    />

    <FilterGroup
      v-model="form.pledgePriceIn"
      :options="pledgePriceOptions"
      :label="$t('labels.filters.models.pledgePrice')"
      name="pledge-price"
      multiple
    />

    <FilterGroup
      v-model="form.priceIn"
      :options="priceOptions"
      :label="$t('labels.filters.models.price')"
      name="price"
      multiple
    />

    <FilterGroup
      v-if="hangarGroupsOptions.length > 0"
      v-model="form.hangarGroupsIn"
      :options="hangarGroupsOptions.map(item => {
        return {
          value: item.slug,
          name: item.name,
        }
      })"
      :label="$t('labels.filters.vehicles.group')"
      name="hangar-group"
      multiple
    />

    <div class="row">
      <div class="col-xs-6">
        <FormInput
          v-model="form.lengthGteq"
          type="number"
          :label="$t('labels.filters.vehicles.lengthGt')"
          :aria-label="$t('labels.filters.vehicles.lengthGt')"
        />
      </div>
      <div class="col-xs-6">
        <FormInput
          v-model="form.lengthLteq"
          type="number"
          :label="$t('labels.filters.vehicles.lengthLt')"
          :aria-label="$t('labels.filters.vehicles.lengthLt')"
        />
      </div>
    </div>

    <div class="row">
      <div class="col-xs-6">
        <FormInput
          v-model="form.pledgePriceGteq"
          type="number"
          :label="$t('labels.filters.vehicles.pledgePriceGt')"
          :aria-label="$t('labels.filters.vehicles.pledgePriceGt')"
        />
      </div>

      <div class="col-xs-6">
        <FormInput
          v-model="form.pledgePriceLteq"
          type="number"
          :label="$t('labels.filters.vehicles.pledgePriceLt')"
          :aria-label="$t('labels.filters.vehicles.pledgePriceLt')"
        />
      </div>
    </div>

    <FormInput
      v-model="form.priceGteq"
      type="number"
      :label="$t('labels.filters.vehicles.priceGt')"
      :aria-label="$t('labels.filters.vehicles.priceGt')"
    />

    <FormInput
      v-model="form.priceLteq"
      type="number"
      :label="$t('labels.filters.vehicles.priceLt')"
      :aria-label="$t('labels.filters.vehicles.priceLt')"
    />

    <RadioList
      v-if="$route.name === 'hangar'"
      v-model="form.purchasedEq"
      :label="$t('labels.filters.vehicles.purchased')"
      :reset-label="$t('labels.all')"
      :options="booleanOptions"
      name="purchased"
    />

    <RadioList
      v-model="form.onSaleEq"
      :label="$t('labels.filters.models.onSale')"
      :reset-label="$t('labels.all')"
      :options="booleanOptions"
      name="sale"
    />

    <RadioList
      v-if="$route.name === 'hangar'"
      v-model="form.publicEq"
      :label="$t('labels.filters.vehicles.public')"
      :reset-label="$t('labels.all')"
      :options="booleanOptions"
      name="public"
    />

    <Btn
      :disabled="!isFilterSelected"
      block
      @click.native="resetFilter"
    >
      <i class="fal fa-times" />
      {{ $t('actions.resetFilter') }}
    </Btn>
  </form>
</template>

<script>
import Filters from 'frontend/mixins/Filters'
import RadioList from 'frontend/components/Form/RadioList'
import FilterGroup from 'frontend/components/Form/FilterGroup'
import FormInput from 'frontend/components/Form/FormInput'
import Btn from 'frontend/components/Btn'

export default {
  name: 'VehiclesFilterForm',

  components: {
    RadioList,
    FilterGroup,
    FormInput,
    Btn,
  },

  mixins: [
    Filters,
  ],

  props: {
    hangarGroupsOptions: {
      type: Array,
      default() {
        return []
      },
    },
  },

  data() {
    const query = this.$route.query.q || {}
    return {
      form: {
        nameCont: query.nameCont,
        onSaleEq: query.onSaleEq,
        purchasedEq: query.purchasedEq,
        publicEq: query.publicEq,
        priceLteq: query.priceLteq,
        priceGteq: query.priceGteq,
        pledgePriceLteq: query.pledgePriceLteq,
        pledgePriceGteq: query.pledgePriceGteq,
        lengthLteq: query.lengthLteq,
        lengthGteq: query.lengthGteq,
        manufacturerIn: query.manufacturerIn || [],
        classificationIn: query.classificationIn || [],
        focusIn: query.focusIn || [],
        sizeIn: query.sizeIn || [],
        priceIn: query.priceIn || [],
        pledgePriceIn: query.pledgePriceIn || [],
        productionStatusIn: query.productionStatusIn || [],
        hangarGroupsIn: query.hangarGroupsIn || [],
        hangarGroupsNotIn: query.hangarGroupsNotIn || [],
      },
    }
  },

  watch: {
    $route() {
      const query = this.$route.query.q || {}
      this.form = {
        nameCont: query.nameCont,
        onSaleEq: query.onSaleEq,
        purchasedEq: query.purchasedEq,
        publicEq: query.publicEq,
        priceLteq: query.priceLteq,
        priceGteq: query.priceGteq,
        pledgePriceLteq: query.pledgePriceLteq,
        pledgePriceGteq: query.pledgePriceGteq,
        lengthLteq: query.lengthLteq,
        lengthGteq: query.lengthGteq,
        manufacturerIn: query.manufacturerIn || [],
        classificationIn: query.classificationIn || [],
        focusIn: query.focusIn || [],
        sizeIn: query.sizeIn || [],
        priceIn: query.priceIn || [],
        pledgePriceIn: query.pledgePriceIn || [],
        productionStatusIn: query.productionStatusIn || [],
        hangarGroupsIn: query.hangarGroupsIn || [],
        hangarGroupsNotIn: query.hangarGroupsNotIn || [],
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
}
</script>
