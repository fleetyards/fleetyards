<template>
  <div class="empty-box">
    <Box
      class="info"
      large
    >
      <h1>{{ $t('headlines.empty') }}</h1>
      <template v-if="isQueryPresent">
        <p>{{ $t('texts.empty.query') }}</p>
        <Btn
          slot="footer"
          :to="{ name: this.$route.name, exact: true }"
          class="pull-right"
        >
          {{ $t('actions.empty.reset') }}
        </Btn>
      </template>
      <p v-else>
        {{ $t('texts.empty.info') }}
      </p>
    </Box>
  </div>
</template>

<script>
import Box from 'frontend/components/Box'
import Btn from 'frontend/components/Btn'

export default {
  components: {
    Box,
    Btn,
  },
  computed: {
    isQueryPresent() {
      return Object.keys(this.$route.query).length > 0
    },
  },
}
</script>

<style lang="scss" scoped>
  @import './styles/index';
</style>
