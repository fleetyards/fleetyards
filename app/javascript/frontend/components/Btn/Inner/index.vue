<template>
  <div class="panel-btn-inner">
    <template v-if="loading">
      {{ t('actions.loading') }}
    </template>
    <template v-else>
      <slot />
    </template>
  </div>
</template>

<script>
import I18n from 'frontend/mixins/I18n'

export default {
  mixins: [I18n],
  props: {
    loading: {
      type: Boolean,
      default: false,
    },
  },
}
</script>
