<template>
  <Btn @click.native="openPriceModal">
    {{ $t('actions.openPriceModal') }}
  </Btn>
</template>

<script lang="ts">
import Vue from 'vue'
import { Component, Prop } from 'vue-property-decorator'
import { Getter } from 'vuex-class'
import Btn from 'frontend/core/components/Btn'
import { displayWarning } from 'frontend/lib/Noty'

@Component<PriceModalBtn>({
  components: {
    Btn,
  },
})
export default class PriceModalBtn extends Vue {
  @Prop({ default: null }) stationSlug!: string

  @Prop({ default: null }) shopId!: string

  @Prop({ default: null }) shopTypes!: string[] | null

  @Prop({ default: null }) commodityItemType!: string

  @Prop({ default: false }) withoutRental!: boolean

  pathOptions: FilterGroupItem[] = [
    {
      value: 'sell',
      name: this.$t('labels.shop.sellPrice'),
    },
    {
      value: 'buy',
      name: this.$t('labels.shop.buyPrice'),
    },
    {
      value: 'rental',
      name: this.$t('labels.shop.rentalPrice'),
    },
  ]

  @Getter('isAuthenticated', { namespace: 'session' }) isAuthenticated

  openPriceModal() {
    if (!this.isAuthenticated) {
      displayWarning({
        text: this.$t('messages.error.commodityPrice.accountRequired'),
      })
      return
    }

    this.$comlink.$emit('open-modal', {
      component: () =>
        import('frontend/components/ShopCommodities/PriceModal/index.vue'),
      props: {
        stationSlug: this.stationSlug,
        shopId: this.shopId,
        commodityItemType: this.commodityItemType,
        shopTypes: this.shopTypes,
        pathOptions: this.pathOptions.filter(
          item => item.value !== 'rental' || this.withoutRental,
        ),
      },
    })
  }
}
</script>
