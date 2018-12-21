<template>
  <Btn
    v-if="isAuthenticated"
    v-tooltip.bottom="t('actions.addToHangar')"
    :clean="clean"
    :small="small"
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
import I18n from 'frontend/mixins/I18n'
import Btn from 'frontend/components/Btn'
import { success } from 'frontend/lib/Noty'
import { mapGetters } from 'vuex'

export default {
  components: {
    Btn,
  },
  mixins: [I18n],
  props: {
    model: {
      type: Object,
      required: true,
    },
    clean: {
      type: Boolean,
      default: false,
    },
    small: {
      type: Boolean,
      default: false,
    },
  },
  computed: {
    ...mapGetters([
      'isAuthenticated',
      'hangar',
    ]),
    inHangar() {
      return !!(this.hangar || []).find(item => item === this.model.slug)
    },
  },
  methods: {
    async add() {
      const response = await this.$api.post('vehicles', { modelId: this.model.id })
      if (!response.error) {
        this.$store.commit('addToHangar', this.model.slug)
        success(this.t('messages.vehicle.add.success', { model: this.model.name }))
      }
    },
  },
}
</script>
