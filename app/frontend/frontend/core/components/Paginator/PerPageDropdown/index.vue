<template>
  <BtnDropdown
    :size="size"
    :variant="variant"
    :mobile-block="true"
    :inline="true"
  >
    <template #label>
      <template v-if="!mobile">{{ $t('labels.pagination.perPage') }}:</template>
      {{ perPage }}
    </template>
    <Btn
      v-for="(step, index) in steps"
      :key="`per-page-drowndown-${uuid}-${index}-${step}`"
      size="small"
      variant="link"
      @click.native="update(step)"
    >
      {{ step }}
    </Btn>
  </BtnDropdown>
</template>

<script>
import { mapGetters } from 'vuex'
import BtnDropdown from '@/frontend/core/components/BtnDropdown/index.vue'
import Btn from '@/frontend/core/components/Btn/index.vue'

export default {
  name: 'PerPageDropdown',

  components: {
    Btn,
    BtnDropdown,
  },

  props: {
    perPage: {
      required: true,
      type: [String, Number],
    },

    size: {
      default: 'default',
      type: String,
      validator(value) {
        return ['default', 'small', 'large'].indexOf(value) !== -1
      },
    },

    steps: {
      default: () => [10, 20, 50, 100],
      type: Array,
    },

    variant: {
      default: 'default',
      type: String,
      validator(value) {
        return (
          ['default', 'transparent', 'link', 'danger', 'dropdown'].indexOf(
            value
          ) !== -1
        )
      },
    },
  },

  computed: {
    ...mapGetters(['mobile']),

    uuid() {
      return this._uid
    },
  },

  methods: {
    update(step) {
      this.$emit('change', step)
    },
  },
}
</script>
