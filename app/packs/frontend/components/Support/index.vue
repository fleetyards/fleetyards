<template>
  <Btn size="small" class="support-button" @click.native="open">
    {{ $t('actions.supportUs') }}
  </Btn>
</template>

<script lang="ts">
import Vue from 'vue'
import { Component } from 'vue-property-decorator'
import Btn from 'frontend/core/components/Btn'

@Component<Support>({
  components: {
    Btn,
  },
})
export default class Support extends Vue {
  open() {
    this.$comlink.$emit('open-modal', {
      component: () => import('frontend/components/Support/Modal'),
      wide: true,
    })
  }
}
</script>
