<template>
  <Modal
    ref="modal"
    :title="info ? $t(`privacySettings.info.${info}.title`) : $t('privacySettings.title')"
  >
    <div
      v-if="info"
      class="cookies-banner"
    >
      <p>
        {{ $t(`privacySettings.info.${info}.text`) }}
      </p>
      <dl>
        <dt>
          Why?
        </dt>
        <dd>
          {{ $t(`privacySettings.info.${info}.why`) }}
        </dd>
        <dt>
          Data Collected
        </dt>
        <dd>
          <ul>
            <li
              v-for="(item, index) in $t(`privacySettings.info.${info}.data`)"
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
          {{ $t(`privacySettings.info.${info}.company`) }}
        </dd>
        <dt>
          Location
        </dt>
        <dd>
          {{ $t(`privacySettings.info.${info}.location`) }}
        </dd>
      </dl>
      <Btn
        inline
        block
        @click.native="hideInfo"
      >
        <i class="fal fa-chevron-left" />
        {{ $t('actions.back') }}
      </Btn>
    </div>
    <div
      v-else
      class="cookies-banner"
    >
      <p>{{ $t(`privacySettings.text`) }}</p>
      <form @submit.prevent="submit">
        <div class="row">
          <div class="col-xs-12">
            <fieldset>
              <legend>{{ $t('privacySettings.essential') }}</legend>
              <div class="form-item">
                <Checkbox
                  :value="true"
                  :label="$t('privacySettings.fontawesome')"
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
                  :label="$t('privacySettings.googleFonts')"
                  disabled
                />
                <i
                  class="info-link fal fa-info-circle"
                  @click="openInfo('googleFonts')"
                />
              </div>
            </fieldset>
            <fieldset>
              <legend>{{ $t('privacySettings.functional') }}</legend>
              <div class="form-item">
                <Checkbox
                  v-model="form.youtube"
                  :label="$t('privacySettings.youtube')"
                />
                <i
                  class="info-link fal fa-info-circle"
                  @click="openInfo('youtube')"
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
            {{ $t('privacySettings.save') }}
          </Btn>
        </div>
      </form>
    </div>
  </Modal>
</template>

<script>
import { mapGetters } from 'vuex'
import Modal from 'frontend/components/Modal'
import Checkbox from 'frontend/components/Form/Checkbox'
import Btn from 'frontend/components/Btn'

export default {
  components: {
    Modal,
    Checkbox,
    Btn,
  },

  data() {
    return {
      info: null,
      form: {
        youtube: false,
      },
    }
  },

  computed: {
    ...mapGetters('session', [
      'cookies',
    ]),
  },

  watch: {
    cookies: {
      handler() {
        this.setupForm()
      },
      deep: true,
    },
  },

  mounted() {
    this.setupForm()
  },

  methods: {
    open() {
      this.$refs.modal.open()
    },

    close() {
      this.$refs.modal.close()
    },

    setupForm() {
      this.form = {
        youtube: this.cookies.youtube,
      }
    },

    submit() {
      this.$store.dispatch('session/updateCookies', {
        ...this.form,
      })

      this.close()
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
