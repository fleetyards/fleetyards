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
import Btn from 'frontend/components/Btn'
import { mapGetters } from 'vuex'

export default {
  components: {
    Btn,
  },
  props: {
    model: {
      type: Object,
      required: true,
    },
    variant: {
      type: String,
      default: 'default',
      validator(value) {
        return ['default', 'panel', 'menu'].indexOf(value) !== -1
      },
    },
  },
  computed: {
    ...mapGetters('session', ['isAuthenticated']),

    ...mapGetters('hangar', ['ships']),

    inHangar() {
      return !!(this.ships || []).find(item => item === this.model.slug)
    },

    btnVariant() {
      if (['panel', 'menu'].includes(this.variant)) {
        return 'link'
      }

      return 'default'
    },

    btnSize() {
      if (['panel', 'menu'].includes(this.variant)) {
        return 'small'
      }

      return 'default'
    },
  },

  methods: {
    async add() {
      if (!this.isAuthenticated) {
        this.$warning({
          text: this.$t('messages.error.accountRequired'),
        })
        return
      }

      const response = await this.$api.post('vehicles', {
        modelId: this.model.id,
      })

      if (!response.error) {
        await this.$store.dispatch('hangar/add', this.model.slug)
        this.$success({
          text: this.$t('messages.vehicle.add.success', {
            model: this.model.name,
          }),
          icon: this.model.storeImageSmall,
        })
      }
    },
  },
}
</script>
