<template>
  <Btn
    v-tooltip="$t('actions.shoppingCart.add')"
    class="add-to-cart"
    variant="link"
    @click.native="addToCart({ item, type })"
  >
    <i class="fal fa-cart-plus" />
  </Btn>
</template>

<script>
import { mapGetters, mapActions } from 'vuex'
import Btn from '@/frontend/core/components/Btn/index.vue'

export default {
  name: 'AddToCartBtn',

  components: {
    Btn,
  },

  props: {
    item: {
      required: true,
      type: Object,
    },

    type: {
      required: true,
      type: String,
    },
  },

  computed: {
    ...mapGetters(['mobile']),
  },

  methods: {
    ...mapActions('shoppingCart', {
      addToCart: 'add',
    }),
  },
}
</script>

<style lang="scss" scoped>
@import 'index.scss';
</style>
