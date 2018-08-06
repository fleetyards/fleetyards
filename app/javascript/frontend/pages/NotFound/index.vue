<template>
  <div class="container">
    <Box
      class="error"
      large>
      <h1>{{ t('headlines.error') }}</h1>
      <p>{{ t('texts.error') }}</p>
    </Box>
  </div>
</template>

<script>
import I18n from 'frontend/mixins/I18n'
import MetaInfo from 'frontend/mixins/MetaInfo'
import Box from 'frontend/components/Box'

export default {
  components: {
    Box,
  },
  mixins: [I18n, MetaInfo],
  metaInfo() {
    return this.getMetaInfo({
      title: this.t('title.notFound'),
    })
  },
}
</script>

<style lang="scss" scoped>
.error {
  p {
    color: darken(red, 10%);
  }
}
</style>
