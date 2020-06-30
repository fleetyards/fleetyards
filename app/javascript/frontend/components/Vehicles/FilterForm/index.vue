<template>
  <form @submit.prevent="filter">
    <FormInput
      id="vehicle-name"
      v-model="form.nameCont"
      translation-key="filters.vehicles.name"
      no-label
      clearable
    />

    <FilterGroup
      v-model="form.manufacturerIn"
      :label="$t('labels.filters.models.manufacturer')"
      fetch-path="manufacturers/with-models"
      name="manufacturer"
      value-attr="slug"
      icon-attr="logo"
      :paginated="true"
      :searchable="true"
      :multiple="true"
      :no-label="true"
    />

    <FilterGroup
      v-model="form.productionStatusIn"
      :label="$t('labels.filters.models.productionStatus')"
      fetch-path="models/production-states"
      name="production-status"
      :multiple="true"
      :no-label="true"
    />

    <FilterGroup
      v-model="form.classificationIn"
      :label="$t('labels.filters.models.classification')"
      fetch-path="models/classifications"
      name="classification"
      :searchable="true"
      :multiple="true"
      :no-label="true"
    />

    <FilterGroup
      v-model="form.focusIn"
      :label="$t('labels.filters.models.focus')"
      fetch-path="models/focus"
      name="focus"
      :searchable="true"
      :multiple="true"
      :no-label="true"
    />

    <FilterGroup
      v-model="form.sizeIn"
      :label="$t('labels.filters.models.size')"
      fetch-path="models/sizes"
      name="size"
      :multiple="true"
      :no-label="true"
    />

    <FilterGroup
      v-model="form.pledgePriceIn"
      :options="pledgePriceOptions"
      :label="$t('labels.filters.models.pledgePrice')"
      name="pledge-price"
      :multiple="true"
      :no-label="true"
    />

    <FilterGroup
      v-model="form.priceIn"
      :options="priceOptions"
      :label="$t('labels.filters.models.price')"
      name="price"
      :multiple="true"
      :no-label="true"
    />

    <FilterGroup
      v-if="hangarGroupsOptions.length > 0"
      v-model="form.hangarGroupsIn"
      :options="
        hangarGroupsOptions.map(item => {
          return {
            value: item.slug,
            name: item.name,
          }
        })
      "
      :label="$t('labels.filters.vehicles.group')"
      name="hangar-group"
      :multiple="true"
      :no-label="true"
    />

    <div class="row">
      <div class="col-6">
        <FormInput
          id="vehicle-length-gteq"
          v-model="form.lengthGteq"
          type="number"
          translation-key="filters.vehicles.lengthGt"
          no-placeholder
        />
      </div>
      <div class="col-6">
        <FormInput
          id="vehicle-length-lteq"
          v-model="form.lengthLteq"
          type="number"
          translation-key="filters.vehicles.lengthLt"
          no-placeholder
        />
      </div>
    </div>

    <div class="row">
      <div class="col-6">
        <FormInput
          id="vehicle-pledge-price-gteq"
          v-model="form.pledgePriceGteq"
          type="number"
          translation-key="filters.vehicles.pledgePriceGt"
          no-placeholder
        />
      </div>

      <div class="col-6">
        <FormInput
          id="vehicle-pledge-price-lteq"
          v-model="form.pledgePriceLteq"
          type="number"
          translation-key="filters.vehicles.pledgePriceLt"
          no-placeholder
        />
      </div>
    </div>

    <FormInput
      id="vehicle-price-gteq"
      v-model="form.priceGteq"
      type="number"
      translation-key="filters.vehicles.priceGt"
      no-placeholder
    />

    <FormInput
      id="vehicle-price-lteq"
      v-model="form.priceLteq"
      type="number"
      translation-key="filters.vehicles.priceLt"
      no-placeholder
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
      v-if="$route.name === 'hangar'"
      v-model="form.loanerEq"
      :label="$t('labels.filters.vehicles.loaner')"
      :reset-label="$t('labels.hide')"
      :options="[
        {
          name: 'Show',
          value: 'true',
        },
        {
          name: 'Only',
          value: 'only',
        },
      ]"
      name="loaner"
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
      :block="true"
      @click.native="resetFilter"
    >
      <i class="fal fa-times" />
      {{ $t('actions.resetFilter') }}
    </Btn>
  </form>
</template>

<script>
import Filters from 'frontend/mixins/Filters'
import RadioList from 'frontend/core/components/Form/RadioList'
import FilterGroup from 'frontend/core/components/Form/FilterGroup'
import FormInput from 'frontend/core/components/Form/FormInput'
import Btn from 'frontend/core/components/Btn'
import {
  booleanOptions,
  priceOptions,
  pledgePriceOptions,
} from 'frontend/utils/Filters'

export default {
  name: 'VehiclesFilterForm',

  components: {
    RadioList,
    FilterGroup,
    FormInput,
    Btn,
  },

  mixins: [Filters],

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
        loanerEq: query.loanerEq,
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

  computed: {
    booleanOptions() {
      return booleanOptions
    },

    priceOptions() {
      return priceOptions
    },

    pledgePriceOptions() {
      return pledgePriceOptions
    },
  },

  watch: {
    $route() {
      const query = this.$route.query.q || {}
      this.form = {
        nameCont: query.nameCont,
        onSaleEq: query.onSaleEq,
        purchasedEq: query.purchasedEq,
        loanerEq: query.loanerEq,
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
    },
  },
}
</script>
