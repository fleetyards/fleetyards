<template>
  <transition
    name="fade"
    appear
  >
    <div
      v-if="!cookiesAccepted"
      class="cookies-banner"
      :class="{
        'cookies-banner-slim': navSlim,
      }"
    >
      <p v-html="$t('texts.cookies')" />
      <Btn
        class="close"
        variant="link"
        inline
        @click.native="acceptCookies"
      >
        <i class="fal fa-times" />
      </Btn>
    </div>
  </transition>
</template>

<script>
import { mapGetters } from 'vuex'
import Btn from 'frontend/components/Btn'

export default {
  components: {
    Btn,
  },

  computed: {
    ...mapGetters('session', [
      'cookiesAccepted',
    ]),

    ...mapGetters('app', [
      'navSlim',
    ]),
  },

  methods: {
    acceptCookies() {
      this.$store.dispatch('session/acceptCookies')
    },
  },
}
</script>

<style lang="scss" scoped>
  @import 'index';
</style>
