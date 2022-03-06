<template>
  <Btn
    v-if="items && items.length"
    v-tooltip="tooltip"
    :variant="variant"
    :size="size"
    :inline="inline"
    @click.native="openStarship42"
  >
    <template v-if="withIcon">
      <i class="fad fa-cube" />
      <span>{{ $t('labels.exportStarship42') }}</span>
    </template>
    <span v-else>
      {{ $t('labels.3dView') }}
    </span>
  </Btn>
</template>

<script>
import { mapGetters } from 'vuex'
import Btn from '@/frontend/core/components/Btn/index.vue'

export default {
  name: 'Starship42Btn',

  components: {
    Btn,
  },

  props: {
    inline: {
      type: Boolean,
      default: false,
    },

    items: {
      type: Array,
      required: true,
    },

    size: {
      type: String,
      default: 'default',
      validator(value) {
        return ['default', 'small', 'large'].indexOf(value) !== -1
      },
    },

    variant: {
      type: String,
      default: 'default',
      validator(value) {
        return (
          ['default', 'transparent', 'link', 'danger', 'dropdown'].indexOf(
            value
          ) !== -1
        )
      },
    },

    withIcon: {
      type: Boolean,
      default: false,
    },
  },

  computed: {
    ...mapGetters(['mobile']),

    basePath() {
      return 'https://starship42.com/fleetview/'
    },

    tooltip() {
      if (this.mobile) {
        return null
      }

      // @ts-ignore
      return this.$t('labels.poweredByStarship42')
    },
  },

  methods: {
    openStarship42() {
      const form = document.createElement('form')
      form.method = 'post'
      form.action = this.basePath
      form.target = '_blank'

      const typeField = document.createElement('input')
      typeField.type = 'hidden'
      typeField.name = 'type'
      typeField.value = 'matrix'
      form.appendChild(typeField)

      this.items.forEach((item) => {
        const model = item.model || item
        const shipField = document.createElement('input')
        shipField.type = 'hidden'
        shipField.name = 's[]'
        shipField.value = model.rsiName

        form.appendChild(shipField)
      })

      document.body.appendChild(form)
      form.submit()
    },
  },
}
</script>
