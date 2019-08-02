<template>
  <div class="empty-box">
    <Box
      class="info"
      large
    >
      <h1>{{ $t('headlines.empty') }}</h1>
      <template v-if="isQueryPresent">
        <p>{{ $t('texts.empty.query') }}</p>
        <div
          slot="footer"
          class="pull-right"
        >
          <Btn
            v-if="isPagePresent"
            @click.native="resetPage"
          >
            {{ $t('actions.empty.resetPage') }}
          </Btn>
          <Btn
            :to="{ name: this.$route.name, exact: true }"
          >
            {{ $t('actions.empty.reset') }}
          </Btn>
        </div>
      </template>
      <p v-else>
        {{ $t('texts.empty.info') }}
      </p>
    </Box>
  </div>
</template>

<script>
import Filters from 'frontend/mixins/Filters'
import Box from 'frontend/components/Box'
import Btn from 'frontend/components/Btn'

export default {
  components: {
    Box,
    Btn,
  },

  mixins: [Filters],

  computed: {
    isQueryPresent() {
      return Object.keys(this.$route.query).length > 0
    },
  },
}
</script>

<style lang="scss" scoped>
  @import 'index';
</style>
