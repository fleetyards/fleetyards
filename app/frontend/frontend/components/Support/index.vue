<template>
  <Btn size="small" class="support-button" @click.native="open">
    {{ $t('actions.supportUs') }}
  </Btn>
</template>

<script>
import Btn from '@/frontend/core/components/Btn/index.vue'

export default {
  name: 'SupportBtn',
  components: {
    Btn,
  },

  methods: {
    open() {
      this.$comlink.$emit('open-modal', {
        component: () =>
          import('@/frontend/components/Support/Modal/index.vue'),
        wide: true,
      })
    },
  },
}
</script>
