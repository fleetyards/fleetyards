<template>
  <div
    v-if="!cookiesAccepted"
    class="cookies-banner"
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
