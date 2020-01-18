<template>
  <transition
    name="fade"
    appear
  >
    <div
      v-if="cookiesVisible"
      class="cookies-banner"
      :class="{
        'cookies-banner-slim': navSlim,
      }"
    >
      <div
        v-if="info"
        class="cookies-banner-inner"
      >
        <h2>{{ $t(`labels.cookies.info.${info}.title`) }}</h2>
        <p>
          {{ $t(`labels.cookies.info.${info}.text`) }}
        </p>
        <dl>
          <dt>
            Why?
          </dt>
          <dd>
            {{ $t(`labels.cookies.info.${info}.why`) }}
          </dd>
          <dt>
            Data Collected
          </dt>
          <dd>
            <ul>
              <li
                v-for="(item, index) in $t(`labels.cookies.info.${info}.data`)"
                :key="index"
              >
                {{ item }}
              </li>
            </ul>
          </dd>
          <dt>
            Company
          </dt>
          <dd>
            {{ $t(`labels.cookies.info.${info}.company`) }}
          </dd>
          <dt>
            Location
          </dt>
          <dd>
            {{ $t(`labels.cookies.info.${info}.location`) }}
          </dd>
        </dl>
        <Btn
          class="close"
          variant="link"
          @click.native="hideInfo"
        >
          <i class="fa fa-times" />
        </Btn>
      </div>
      <div
        v-else
        class="cookies-banner-inner"
      >
        <h2>{{ $t(`labels.cookies.title`) }}</h2>
        <p>{{ $t(`labels.cookies.text`) }}</p>
        <form @submit.prevent="submit">
          <div class="row">
            <div class="col-xs-12">
              <fieldset>
                <legend>{{ $t('labels.cookies.essential') }}</legend>
                <div class="form-item">
                  <Checkbox
                    :value="true"
                    :label="$t('labels.cookies.fontawesome')"
                    disabled
                  />
                  <i
                    class="info-link fal fa-info-circle"
                    @click="openInfo('fontawesome')"
                  />
                </div>
                <div class="form-item">
                  <Checkbox
                    :value="true"
                    :label="$t('labels.cookies.googleFonts')"
                    disabled
                  />
                  <i
                    class="info-link fal fa-info-circle"
                    @click="openInfo('googleFonts')"
                  />
                </div>
              </fieldset>
              <fieldset>
                <legend>{{ $t('labels.cookies.functional') }}</legend>
                <div class="form-item">
                  <Checkbox
                    v-model="form.ahoy"
                    :label="$t('labels.cookies.ahoy')"
                  />
                  <i
                    class="info-link fal fa-info-circle"
                    @click="openInfo('ahoy')"
                  />
                </div>
              </fieldset>
            </div>
          </div>
          <div class="cookies-banner-actions">
            <Btn
              type="submit"
              data-test="accept-cookies"
              block
              inline
            >
              {{ $t('labels.cookies.save') }}
            </Btn>
          </div>
        </form>
      </div>
    </div>
  </transition>
</template>

<script>
import { mapGetters } from 'vuex'
import Checkbox from 'frontend/components/Form/Checkbox'
import Btn from 'frontend/components/Btn'

export default {
  components: {
    Checkbox,
    Btn,
  },

  data() {
    return {
      info: null,
      form: {
        ahoy: false,
      },
    }
  },

  computed: {
    ...mapGetters('session', [
      'cookies',
    ]),

    ...mapGetters('app', [
      'navSlim',
    ]),

    cookiesVisible() {
      return this.cookies.visible
    },
  },

  watch: {
    cookiesVisible() {
      if (this.cookiesVisible) {
        this.$store.commit('app/showOverlay')
      } else {
        this.$store.commit('app/hideOverlay')
      }
    },
  },

  mounted() {
    this.setupForm()

    if (this.cookiesVisible) {
      this.$store.commit('app/showOverlay')
    }
  },

  methods: {
    setupForm() {
      this.form = {
        ahoy: this.cookies.ahoy,
      }
    },

    submit() {
      this.$store.dispatch('session/setCookies', {
        ...this.form,
        visible: false,
      })
    },

    openInfo(key) {
      this.info = key
    },

    hideInfo() {
      this.info = null
    },
  },
}
</script>

<style lang="scss" scoped>
  @import 'index';
</style>
