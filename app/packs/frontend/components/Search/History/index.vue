<template>
  <div class="row justify-content-center">
    <div class="col-12 col-lg-6">
      <Panel>
        <div class="panel-heading panel-heading-with-actions">
          <h2 class="panel-title">
            {{ $t('headlines.searchHistory') }}
          </h2>
          <div class="panel-heading-actions">
            <Btn
              v-if="history.length"
              size="small"
              :inline="true"
              :aria-label="$t('actions.clearHistory')"
              @click.native="resetHistory"
            >
              <i v-if="mobile" class="fa fa-times" />
              <template v-else>
                {{ $t('actions.clearHistory') }}
              </template>
            </Btn>
          </div>
        </div>
        <div class="search-history">
          <template v-if="history.length">
            <div
              v-for="(entry, index) in filteredHistory"
              :key="index"
              class="search-history-item"
              @click="restore(entry.search)"
            >
              {{ entry.search }}
            </div>
          </template>
          <div v-else class="search-history-empty">...</div>
        </div>
      </Panel>
      <div class="text-center">
        <Btn v-if="history.length > page * perPage" @click.native="showMore">
          {{ $t('actions.showMore') }}
        </Btn>
      </div>
    </div>
  </div>
</template>

<script>
import { mapGetters } from 'vuex'
import Btn from 'frontend/core/components/Btn'
import Panel from 'frontend/core/components/Panel'

export default {
  name: 'SearchHistory',

  components: {
    Btn,
    Panel,
  },

  data() {
    return {
      page: 1,
      perPage: 30,
    }
  },

  computed: {
    ...mapGetters(['mobile']),

    ...mapGetters('search', ['history']),

    filteredHistory() {
      return this.history.slice(0, this.page * this.perPage)
    },
  },

  methods: {
    restore(search) {
      this.$emit('restore', search)
    },

    showMore() {
      this.page += 1
    },

    resetHistory() {
      this.$store.dispatch('search/reset')
    },
  },
}
</script>

<style lang="scss" scoped>
@import 'index';
</style>
