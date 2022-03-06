<template>
  <Btn @click.native="openPriceModal">
    {{ $t('actions.openPriceModal') }}
  </Btn>
</template>

<script>
import { mapGetters } from 'vuex'
import Btn from '@/frontend/core/components/Btn/index.vue'
import { displayWarning } from '@/frontend/lib/Noty'

export default {
  name: 'PriceModalBtn',

  components: {
    Btn,
  },

  props: {
    commodityItemType: {
      type: String,
      default: null,
    },

    shopId: {
      type: String,
      default: null,
    },

    shopTypes: {
      type: Array,
      default: null,
    },

    stationSlug: {
      type: String,
      default: null,
    },

    withoutRental: {
      type: Boolean,
      default: false,
    },
  },

  data() {
    return {
      pathOptions: [
        {
          name: this.$t('labels.shop.sellPrice'),
          value: 'sell',
        },
        {
          name: this.$t('labels.shop.buyPrice'),
          value: 'buy',
        },
        {
          name: this.$t('labels.shop.rentalPrice'),
          value: 'rental',
        },
      ],
    }
  },

  computed: {
    ...mapGetters('session', ['isAuthenticated']),
  },

  methods: {
    openPriceModal() {
      if (!this.isAuthenticated) {
        displayWarning({
          text: this.$t('messages.error.commodityPrice.accountRequired'),
        })
        return
      }

      this.$comlink.$emit('open-modal', {
        component: () =>
          import('@/frontend/components/ShopCommodities/PriceModal/index.vue'),
        props: {
          commodityItemType: this.commodityItemType,
          pathOptions: this.pathOptions.filter(
            (item) => item.value !== 'rental' || this.withoutRental
          ),
          shopId: this.shopId,
          shopTypes: this.shopTypes,
          stationSlug: this.stationSlug,
        },
      })
    },
  },
}
</script>
