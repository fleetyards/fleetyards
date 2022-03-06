<template>
  <div>
    <template v-if="availableCargo">
      <span v-html="tPriceLong(price * availableCargo)" />
      <small v-html="tPrice(price)" />
    </template>
    <span v-else v-html="tPriceLong(price)" />
  </div>
</template>

<script>
export default {
  name: 'TradeRoutePrice',

  props: {
    availableCargo: {
      default: null,
      type: Number,
    },
    average: {
      default: false,
      type: Boolean,
    },

    priceType: {
      default: 'buy',
      type: String,
    },

    tradeRoute: {
      required: true,
      type: Object,
    },
  },
  computed: {
    price() {
      if (this.average) {
        return this.tradeRoute[`average${this.priceTypeCapitalized}Price`]
      }

      return this.tradeRoute[`${this.priceType}Price`]
    },

    priceTypeCapitalized() {
      return this.priceType.charAt(0).toUpperCase() + this.priceType.slice(1)
    },
  },

  methods: {
    tPrice(price) {
      return this.$toUEC(price, this.$t('labels.uecPerUnit'))
    },

    tPriceLong(price) {
      return this.$t(`labels.tradeRoutes.${this.priceType}`, {
        uec: this.tPrice(price),
      })
    },
  },
}
</script>
