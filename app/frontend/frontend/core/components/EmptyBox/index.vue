<template>
  <transition name="fade">
    <div v-if="visible" class="empty-box">
      <Box class="info" :large="true">
        <h1>{{ $t('headlines.empty') }}</h1>
        <template v-if="isQueryPresent">
          <p>{{ $t('texts.empty.query') }}</p>
          <div slot="footer" class="empty-box-actions">
            <Btn v-if="isPagePresent" @click.native="resetPage">
              {{ $t('actions.empty.resetPage') }}
            </Btn>
            <Btn :to="{ name: $route.name }" :exact="true">
              {{ $t('actions.empty.reset') }}
            </Btn>
          </div>
        </template>
        <p v-else>
          {{ $t('texts.empty.info') }}
        </p>
      </Box>
    </div>
  </transition>
</template>

<script>
import Box from '@/frontend/core/components/Box'
import Btn from '@/frontend/core/components/Btn'

export default {
  name: 'EmptyBox',

  components: {
    Box,
    Btn,
  },

  props: {
    visible: {
      type: Boolean,
      required: true,
    },

    ignoreFilter: {
      type: Boolean,
      default: false,
    },
  },

  computed: {
    isPagePresent() {
      return !!this.$route.query.page
    },

    isQueryPresent() {
      return !this.ignoreFilter && Object.keys(this.$route.query).length > 0
    },
  },

  methods: {
    resetPage() {
      const query = {
        ...JSON.parse(JSON.stringify(this.$route.query)),
      }

      if (query.page) {
        delete query.page
      }

      this.$router
        .replace({
          name: this.$route.name,
          query: {
            ...query,
            q: this.$route.query.q || {},
          },
        })
        // eslint-disable-next-line @typescript-eslint/no-empty-function
        .catch((_err) => {})
    },
  },
}
</script>
