<template>
  <div class="container">
    <Box
      class="error"
      large
    >
      <h1>{{ $t('headlines.error') }}</h1>
      <p>{{ $t('texts.error') }}</p>
      <template #footer>
        <Btn :to="{name: 'home', exact: true}">
          <i class="fa fa-chevron-left" />
          {{ $t('actions.backToHome').toUpperCase() }}
        </Btn>
      </template>
    </Box>
  </div>
</template>

<script>
import MetaInfo from 'frontend/mixins/MetaInfo'
import Box from 'frontend/components/Box'
import Btn from 'frontend/components/Btn'

export default {
  components: {
    Box,
    Btn,
  },
  mixins: [MetaInfo],
  metaInfo() {
    return this.getMetaInfo({
      title: this.$t('title.notFound'),
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
