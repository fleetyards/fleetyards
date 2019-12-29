<template>
  <transition name="fade">
    <div
      v-if="!online"
      class="network-status"
    >
      {{ $t('labels.networkStatusOffline') }}
    </div>
  </transition>
</template>

<script>
import { mapGetters } from 'vuex'

export default {
  computed: {
    ...mapGetters([
      'online',
    ]),
  },

  created() {
    this.checkOnline()

    window.addEventListener('online', this.checkOnline)
    window.addEventListener('offline', this.checkOnline)
  },

  beforeDestroy() {
    window.removeEventListener('online', this.checkOnline)
    window.removeEventListener('offline', this.checkOnline)
  },

  methods: {
    checkOnline() {
      this.$store.commit('setOnlineStatus', window.navigator.onLine)
    },
  },
}
</script>

<style lang="scss" scoped>
  @import 'index';
</style>
