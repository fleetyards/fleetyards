<template>
  <form @submit.prevent="filter">
    <FormInput
      v-model="form.nameCont"
      :placeholder="t('placeholders.filters.vehicles.name')"
      :aria-label="t('placeholders.filters.vehicles.name')"
    />
    <FilterGroup
      v-model="form.manufacturerIn"
      :label="t('labels.filters.models.manufacturer')"
      :fetch="fetchManufacturers"
      name="manufacturer"
      value-attr="slug"
      icon-attr="logo"
      paginated
      searchable
      multiple
    />
    <FilterGroup
      v-model="form.productionStatusIn"
      :label="t('labels.filters.models.productionStatus')"
      :fetch="fetchProductionStatus"
      name="production-status"
      multiple
    />
    <FilterGroup
      v-model="form.classificationIn"
      :label="t('labels.filters.models.classification')"
      :fetch="fetchClassifications"
      name="classification"
      searchable
      multiple
    />
    <FilterGroup
      v-model="form.focusIn"
      :label="t('labels.filters.models.focus')"
      :fetch="fetchFocus"
      name="focus"
      searchable
      multiple
    />
    <FilterGroup
      v-model="form.sizeIn"
      :label="t('labels.filters.models.size')"
      :fetch="fetchSize"
      name="size"
      multiple
    />
    <FilterGroup
      v-model="form.pledgePriceIn"
      :options="pledgePriceOptions"
      :label="t('labels.filters.models.pledgePrice')"
      name="pledge-price"
      multiple
    />
    <FilterGroup
      v-model="form.priceIn"
      :options="priceOptions"
      :label="t('labels.filters.models.price')"
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
      :label="t('labels.filters.vehicles.group')"
      name="hangar-group"
      multiple
    />
    <RadioList
      v-if="$route.name === 'hangar'"
      v-model="form.purchasedEq"
      :label="t('labels.filters.vehicles.purchased')"
      :reset-label="t('labels.all')"
      :options="booleanOptions"
      name="purchased"
    />
    <RadioList
      v-model="form.onSaleEq"
      :label="t('labels.filters.models.onSale')"
      :reset-label="t('labels.all')"
      :options="booleanOptions"
      name="sale"
    />
    <Btn
      :disabled="!isFilterSelected"
      block
      @click.native="reset"
    >
      <i class="fal fa-times" />
      {{ t('actions.resetFilter') }}
    </Btn>
  </form>
</template>

<script>
import I18n from 'frontend/mixins/I18n'
import Filters from 'frontend/mixins/Filters'
import RadioList from 'frontend/components/Form/RadioList'
import FilterGroup from 'frontend/components/Form/FilterGroup'
import FormInput from 'frontend/components/Form/FormInput'
import Btn from 'frontend/components/Btn'

export default {
  components: {
    RadioList,
    FilterGroup,
    FormInput,
    Btn,
  },
  mixins: [I18n, Filters],
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
