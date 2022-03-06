<template>
  <div class="profit">
    <span v-if="availableCargo" v-html="tPrice(profit * availableCargo)" />
    <span v-else v-html="tPrice(profit)" />
    <small class="profit-percent">({{ profitPerUnitPercent }} %)</small>
  </div>
</template>

<script>
export default {
  name: 'TradeRouteProfit',

  props: {
    availableCargo: {
      default: null,
      type: Number,
    },

    average: {
      default: false,
      type: Boolean,
    },

    tradeRoute: {
      required: true,
      type: Object,
    },
  },
  computed: {
    profit() {
      if (this.average) {
        return this.tradeRoute.averageProfitPerUnit
      }

      return this.tradeRoute.profitPerUnit
    },

    profitPerUnitPercent() {
      if (this.average) {
        return this.tradeRoute.averageProfitPerUnitPercent
      }

      return this.tradeRoute.profitPerUnitPercent
    },
  },

  methods: {
    tPrice(price) {
      return this.$toUEC(price, this.$t('labels.uecPerUnit'))
    },
  },
}
</script>
