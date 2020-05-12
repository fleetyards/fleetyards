<template>
  <div class="container">
    <Box class="error" large>
      <h1>{{ $t('headlines.error') }}</h1>
      <p>{{ $t('texts.error') }}</p>
      <template #footer>
        <Btn :to="{ name: 'home' }" :exact="true">
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
}
</script>

<style lang="scss" scoped>
@import 'index';
</style>
