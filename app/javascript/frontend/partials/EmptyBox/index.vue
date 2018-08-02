<template>
  <div class="empty-box">
    <Box
      class="info"
      large>
      <h1>{{ t('headlines.empty') }}</h1>
      <p>{{ t('texts.empty') }}</p>
    </Box>
  </div>
</template>

<script>
import I18n from 'frontend/mixins/I18n'
import Box from 'frontend/components/Box'

export default {
  components: {
    Box,
  },
  mixins: [I18n],
}
</script>

<style lang="scss" scoped>
  @import "./styles/index";
</style>
