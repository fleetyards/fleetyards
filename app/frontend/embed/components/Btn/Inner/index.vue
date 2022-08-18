<template>
  <div class="panel-btn-inner">
    <template v-if="loading">
      {{ $t('actions.loading') }}
    </template>
    <template v-else>
      <slot />
    </template>
  </div>
</template>

<script>
export default {
  name: 'BtnInner',

  props: {
    loading: {
      type: Boolean,
      default: false,
    },
  },
}
</script>
