<template>
  <li class="gap disabled">
    <a v-html="t('pagination.gap')" />
  </li>
</template>

<script>
import I18n from 'frontend/mixins/I18n'

export default {
  mixins: [I18n],
}
</script>
