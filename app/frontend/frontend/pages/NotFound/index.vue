<template>
  <div class="container">
    <Box class="error" :large="true">
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
import Box from '@/frontend/core/components/Box/index.vue'
import Btn from '@/frontend/core/components/Btn/index.vue'
import MetaInfo from '@/frontend/mixins/MetaInfo'

export default {
  name: 'NotFound',
  components: {
    Box,
    Btn,
  },

  mixins: [MetaInfo],
}
</script>

<style lang="scss" scoped>
@import 'index.scss';
</style>
