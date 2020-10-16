<template>
  <Modal :title="title">
    <div v-if="info" class="cookies-banner">
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
    </div>
    <div v-else-if="internalSettings" class="cookies-banner">
      <p>{{ $t(`privacySettings.text`) }}</p>
      <form @submit.prevent="submit">
        <div class="row">
          <div class="col-12">
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
                  v-model="form.ahoy"
                  :label="$t('privacySettings.ahoy')"
                />
                <i
                  class="info-link fal fa-info-circle"
                  @click="openInfo('ahoy')"
                />
              </div>
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
        <div class="cookies-banner-actions" />
      </form>
    </div>
    <div v-else class="cookies-banner">
      <p>{{ $t('privacySettings.introduction.paragraph1') }}</p>
      <p>{{ $t('privacySettings.introduction.paragraph2') }}</p>
      <p>
        {{ $t('privacySettings.introduction.paragraph3') }}
        <Btn
          variant="link"
          :text-inline="true"
          :to="{ name: 'privacy-policy' }"
        >
          {{ $t('nav.privacyPolicy') }}
        </Btn>
        .
      </p>
    </div>
    <template #footer>
      <div class="cookies-banner-actions">
        <Btn v-if="info" :inline="true" :block="true" @click.native="hideInfo">
          <i class="fal fa-chevron-left" />
          {{ $t('actions.back') }}
        </Btn>
        <Btn
          v-else-if="internalSettings"
          data-test="save-privacy-settings"
          :block="true"
          :inline="true"
          @click.native="submit"
        >
          {{ $t('privacySettings.save') }}
        </Btn>
        <template v-else>
          <Btn
            data-test="show-settings"
            :inline="true"
            variant="link"
            @click.native="showSettings"
          >
            {{ $t('privacySettings.editSettings') }}
          </Btn>
          <Btn data-test="accept-cookies" :inline="true" @click.native="accept">
            {{ $t('privacySettings.accept') }}
          </Btn>
        </template>
      </div>
    </template>
  </Modal>
</template>

<script lang="ts">
import Vue from 'vue'
import { Component, Prop, Watch } from 'vue-property-decorator'
import { Getter } from 'vuex-class'
import Modal from 'frontend/core/components/AppModal/Modal'
import Checkbox from 'frontend/core/components/Form/Checkbox'
import Btn from 'frontend/core/components/Btn'

@Component<PrivacySettings>({
  components: {
    Modal,
    Checkbox,
    Btn,
  },
})
export default class PrivacySettings extends Vue {
  @Prop({ default: false }) settings: boolean

  info: any = null

  internalSettings: boolean = false

  form: PrivacySettingForm = {
    ahoy: false,
    youtube: false,
  }

  @Getter('cookies', { namespace: 'cookies' }) cookies: any

  @Getter('infoVisible', { namespace: 'cookies' }) infoVisible: boolean

  get title() {
    if (this.info) {
      return this.$t(`privacySettings.info.${this.info}.title`)
    }
    if (this.internalSettings) {
      return this.$t('privacySettings.title')
    }

    return this.$t('privacySettings.introduction.title')
  }

  @Watch('cookies', { deep: true })
  onCookiesChange() {
    this.setupForm()
  }

  mounted() {
    this.internalSettings = this.settings
    this.setupForm()
  }

  showSettings() {
    this.internalSettings = true
  }

  close() {
    this.$comlink.$emit('close-modal', 'privacySetting', true)
  }

  setupForm() {
    this.form = {
      ahoy: this.cookies.ahoy,
      youtube: this.cookies.youtube,
    }
  }

  submit() {
    this.$store.dispatch('cookies/updateAcceptedCookies', {
      ...this.form,
    })

    this.$store.dispatch('cookies/hideInfo')

    this.close()
  }

  accept() {
    this.$store.dispatch('cookies/updateAcceptedCookies', {
      ahoy: true,
      youtube: true,
    })

    this.$store.dispatch('cookies/hideInfo')

    this.close()
  }

  openInfo(key) {
    this.info = key
  }

  hideInfo() {
    this.info = null
  }
}
</script>

<style lang="scss" scoped>
@import 'index';
</style>
