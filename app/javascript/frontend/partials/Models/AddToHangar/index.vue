<template>
  <Btn
    v-if="isAuthenticated"
    v-tooltip.bottom="$t('actions.addToHangar')"
    :variant="variant === 'panel' ? 'link' : 'default'"
    :size="variant === 'panel' ? 'small' : 'default'"
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
import { success } from 'frontend/lib/Noty'
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
        return ['default', 'panel'].indexOf(value) !== -1
      },
    },
  },
  computed: {
    ...mapGetters('session', [
      'isAuthenticated',
    ]),
    ...mapGetters('hangar', [
      'ships',
    ]),
    inHangar() {
      return !!(this.ships || []).find(item => item === this.model.slug)
    },
  },
  methods: {
    async add() {
      const response = await this.$api.post('vehicles', { modelId: this.model.id })
      if (!response.error) {
        this.$store.dispatch('hangar/add', this.model.slug)
        success(this.$t('messages.vehicle.add.success', { model: this.model.name }))
      }
    },
  },
}
</script>
