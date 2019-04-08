<template>
  <div class="empty-box">
    <Box
      class="info"
      large
    >
      <h1>{{ t('headlines.empty') }}</h1>
      <template v-if="isQueryPresent">
        <p>{{ t('texts.empty.query') }}</p>
        <InternalLink
          slot="footer"
          :route="{ name: this.$route.name }"
          class="pull-right"
          exact
        >
          {{ t('actions.empty.reset') }}
        </InternalLink>
      </template>
      <p v-else>
        {{ t('texts.empty.info') }}
      </p>
    </Box>
  </div>
</template>

<script>
import I18n from 'frontend/mixins/I18n'
import Box from 'frontend/components/Box'
import InternalLink from 'frontend/components/InternalLink'

export default {
  components: {
    Box,
    InternalLink,
  },
  mixins: [I18n],
  computed: {
    isQueryPresent() {
      return Object.keys(this.$route.query).length > 0
    },
  },
}
</script>

<style lang="scss" scoped>
  @import "./styles/index";
</style>
