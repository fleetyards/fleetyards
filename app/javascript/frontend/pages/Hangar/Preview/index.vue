<template>
  <section class="container hangar">
    <div class="row">
      <div class="col-12">
        <div class="row">
          <div class="col-12">
            <h1 class="sr-only">
              {{ $t('headlines.hangar.preview.h1') }}
            </h1>
          </div>
        </div>

        <div class="row">
          <div class="col-12">
            <h2 class="text-center main-headline">
              {{ $t('headlines.hangar.preview.h2') }}
            </h2>
          </div>
        </div>

        <hr class="large-spacer" />

        <div class="row">
          <div class="col-12">
            <h3 class="text-center main-subheadline">
              {{ $t('headlines.hangar.preview.h3') }}
            </h3>
          </div>
        </div>

        <br />

        <div class="row">
          <div class="col-12 col-lg-4">
            <Panel class="info-box" transparency="more">
              <div class="panel-heading">
                <h2 class="panel-title text-center">
                  {{ $t('texts.hangarPreview.notified.headline') }}
                </h2>
              </div>
              <div class="panel-body text-center">
                <p v-html="$t('texts.hangarPreview.notified.text')" />
              </div>
            </Panel>
          </div>
          <div class="col-12 col-lg-4">
            <Panel class="info-box" transparency="more">
              <div class="panel-heading">
                <h2 class="panel-title text-center">
                  {{ $t('texts.hangarPreview.manage.headline') }}
                </h2>
              </div>
              <div class="panel-body text-center">
                <p v-html="$t('texts.hangarPreview.manage.text')" />
              </div>
            </Panel>
          </div>
          <div class="col-12 col-lg-4">
            <Panel class="info-box" transparency="more">
              <div class="panel-heading">
                <h2 class="panel-title text-center">
                  {{ $t('texts.hangarPreview.fleetchart.headline') }}
                </h2>
              </div>
              <div class="panel-body text-center">
                <p v-html="$t('texts.hangarPreview.fleetchart.text')" />
              </div>
            </Panel>
          </div>
        </div>

        <hr class="large-spacer" />

        <div class="row justify-content-center">
          <div class="col-12 col-lg-4">
            <Btn
              :to="{
                name: 'signup',
                params: {
                  redirectToRoute: 'hangar',
                },
              }"
              data-test="signup"
              size="large"
              :block="true"
            >
              {{ $t('actions.signUp') }}
            </Btn>

            <hr />

            <p class="text-center">
              {{ $t('labels.alreadyRegistered') }}
            </p>

            <Btn
              :to="{
                name: 'login',
                params: {
                  redirectToRoute: 'hangar',
                },
              }"
              data-test="login"
              :block="true"
              @click.native="hidePreview"
            >
              {{ $t('actions.login') }}
            </Btn>
          </div>
        </div>
      </div>
    </div>
  </section>
</template>

<script>
import MetaInfo from 'frontend/mixins/MetaInfo'

import Btn from 'frontend/components/Btn'
import Panel from 'frontend/components/Panel'

export default {
  name: 'HangarPreview',

  components: {
    Btn,
    Panel,
  },

  mixins: [MetaInfo],

  methods: {
    hidePreview() {
      this.$store.dispatch('hangar/hidePreview')
    },
  },
}
</script>

<style lang="scss" scoped>
@import 'index';
</style>
