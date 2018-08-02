<template>
  <Btn
    :clear="clear"
    :disabled="disabled"
    class="submit-button"
    type="submit"
    large
  >
    <template v-if="loading">
      {{ t('actions.loading') }}
    </template>
    <template v-else>
      <template v-if="text">
        {{ text }}
      </template>
      <slot v-else />
    </template>
  </Btn>
</template>

<script>
import I18n from 'frontend/mixins/I18n'
import Btn from 'frontend/components/Btn'

export default {
  components: {
    Btn,
  },
  mixins: [I18n],
  props: {
    loading: {
      type: Boolean,
      default: false,
    },
    text: {
      type: String,
      default: '',
    },
    clear: {
      type: Boolean,
      default: false,
    },
  },
  computed: {
    disabled() {
      return this.loading ? 'disabled' : null
    },
  },
}
</script>

<style lang="scss" scoped>
  .submit-button {
    min-width: 140px;
  }
</style>
