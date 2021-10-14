<template>
  <div>
    <template v-if="availableCargo">
      <span v-html="tPriceLong(price * availableCargo)" />
      <small v-html="tPrice(price)" />
    </template>
    <span v-else v-html="tPriceLong(price)" />
  </div>
</template>

<script lang="ts">
import Vue from 'vue'
import { Component, Prop } from 'vue-property-decorator'

@Component<TradeRoutePrice>({})
export default class TradeRoutePrice extends Vue {
  get priceTypeCapitalized() {
    return this.priceType.charAt(0).toUpperCase() + this.priceType.slice(1)
  }

  get price() {
    if (this.average) {
      return this.tradeRoute[`average${this.priceTypeCapitalized}Price`]
    }

    return this.tradeRoute[`${this.priceType}Price`]
  }

  @Prop({ required: true }) tradeRoute!: TradeRoute

  @Prop({ default: 'buy' }) priceType!: string

  @Prop({ default: null }) availableCargo!: Number

  @Prop({ default: false }) average!: ToTextBooleanArg

  tPrice(price) {
    return this.$toUEC(price, this.$t('labels.uecPerUnit'))
  }

  tPriceLong(price) {
    return this.$t(`labels.tradeRoutes.${this.priceType}`, {
      uec: this.tPrice(price),
    })
  }
}
</script>
