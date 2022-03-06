<template>
  <Btn
    :key="`add-to-hangar-${model.slug}`"
    v-tooltip.bottom="$t('actions.addToHangar')"
    :variant="btnVariant"
    :size="btnSize"
    :inline="variant === 'menu'"
    data-test="add-to-hangar"
    @click.native="add"
  >
    <span v-show="inHangar">
      <i class="fa fa-bookmark" />
    </span>
    <span v-show="!inHangar">
      <i class="fal fa-bookmark" />
    </span>
  </Btn>
</template>

<script>
import { mapGetters } from 'vuex'
import Btn from '@/frontend/core/components/Btn/index.vue'
import { displayWarning } from '@/frontend/lib/Noty'

export default {
  name: 'AddToHangar',

  components: {
    Btn,
  },

  props: {
    model: {
      required: true,
      type: Object,
    },

    variant: {
      default: 'default',
      type: String,
      validator(value) {
        return ['default', 'panel', 'menu', 'list'].includes(value)
      },
    },
  },

  computed: {
    ...mapGetters('session', ['isAuthenticated']),
    ...mapGetters('hangar', ['ships']),

    btnSize() {
      if (['panel', 'menu', 'list'].includes(this.variant)) {
        return 'small'
      }

      return 'default'
    },

    btnVariant() {
      if (['panel', 'menu'].includes(this.variant)) {
        return 'link'
      }

      return 'default'
    },

    inHangar() {
      return !!(this.ships || []).find((item) => item === this.model.slug)
    },
  },

  methods: {
    async add() {
      if (!this.isAuthenticated) {
        displayWarning({
          text: this.$t('messages.error.hangar.accountRequired'),
        })
        return
      }

      this.$comlink.$emit('open-modal', {
        component: () =>
          import('@/frontend/components/Models/AddToHangarModal/index.vue'),
        props: {
          model: this.model,
        },
      })
    },
  },
}
</script>
