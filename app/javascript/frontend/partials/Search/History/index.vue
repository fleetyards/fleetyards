<template>
  <div class="row">
    <div class="col-xs-12 col-md-6 col-md-push-3">
      <Panel>
        <div class="panel-heading panel-heading-with-actions">
          <h2 class="panel-title">
            {{ $t('headlines.searchHistory') }}
          </h2>
          <div class="panel-heading-actions">
            <Btn
              v-if="history.length"
              size="small"
              inline
              :aria-label="$t('actions.clearHistory')"
              @click.native="resetHistory"
            >
              <i
                v-if="mobile"
                class="fa fa-times"
              />
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
          <div
            v-else
            class="search-history-empty"
          >
            ...
          </div>
        </div>
      </Panel>
      <div class="text-center">
        <Btn
          v-if="history.length > (page * perPage)"
          @click.native="showMore"
        >
          {{ $t('actions.showMore') }}
        </Btn>
      </div>
    </div>
  </div>
</template>

<script>
import { mapGetters } from 'vuex'
import Btn from 'frontend/components/Btn'
import Panel from 'frontend/components/Panel'

export default {
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
    ...mapGetters([
      'mobile',
    ]),

    ...mapGetters('search', [
      'history',
    ]),

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
