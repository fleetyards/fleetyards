<template>
  <div>
    <transition
      name="fade"
      appear
    >
      <div
        v-if="cookiesInfoVisible"
        class="cookies-banner"
        :class="{
          'cookies-banner-slim': navSlim,
        }"
      >
        <p>
          <b>{{ $t('cookies.title') }}</b>
          {{ $t('cookies.paragraph1') }} <Btn
            variant="link"
            text-inline
            :to="{name: 'privacy-policy'}"
          >
            {{ $t('nav.privacyPolicy') }}
          </Btn>.
          {{ $t('cookies.paragraph2') }} <Btn
            variant="link"
            text-inline
            @click.native="openPrivacySettings"
          >
            {{ $t('nav.privacySettings') }}
          </Btn>.
        </p>
        <Btn
          class="close"
          variant="link"
          inline
          @click.native="hideInfo"
        >
          <i class="fal fa-times" />
        </Btn>
      </div>
    </transition>
  </div>
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
      'cookiesInfoVisible',
    ]),

    ...mapGetters('app', [
      'navSlim',
    ]),
  },

  methods: {
    hideInfo() {
      this.$store.dispatch('session/hideCookiesInfo')
    },

    openPrivacySettings() {
      this.$comlink.$emit('openPrivacySettings')
    },
  },
}
</script>

<style lang="scss" scoped>
  @import 'index';
</style>
