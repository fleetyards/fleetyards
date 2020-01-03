<template>
  <section class="container fleet">
    <div class="row">
      <div class="col-xs-12">
        <div class="row">
          <div class="col-xs-12">
            <h1 class="sr-only">
              {{ $t('headlines.fleets.preview.h1') }}
            </h1>
          </div>
        </div>

        <div class="row">
          <div class="col-xs-12">
            <h2 class="text-center main-headline">
              {{ $t('headlines.fleets.preview.h2') }}
            </h2>
          </div>
        </div>

        <hr class="large-spacer">

        <div class="row">
          <div class="col-xs-12">
            <h3 class="text-center main-subheadline">
              {{ $t('headlines.fleets.preview.h3') }}
            </h3>
          </div>
        </div>

        <br>

        <div class="flex-row">
          <div class="col-xs-12 col-md-4">
            <Panel
              class="info-box"
              transparency="more"
            >
              <div class="panel-heading">
                <h2 class="panel-title text-center">
                  {{ $t('texts.fleetPreview.notified.headline') }}
                </h2>
              </div>
              <div class="panel-body text-center">
                <p v-html="$t('texts.fleetPreview.notified.text')" />
              </div>
            </Panel>
          </div>
          <div class="col-xs-12 col-md-4">
            <Panel
              class="info-box"
              transparency="more"
            >
              <div class="panel-heading">
                <h2 class="panel-title text-center">
                  {{ $t('texts.fleetPreview.overview.headline') }}
                </h2>
              </div>
              <div class="panel-body text-center">
                <p v-html="$t('texts.fleetPreview.overview.text')" />
              </div>
            </Panel>
          </div>
          <div class="col-xs-12 col-md-4">
            <Panel
              class="info-box"
              transparency="more"
            >
              <div class="panel-heading">
                <h2 class="panel-title text-center">
                  {{ $t('texts.fleetPreview.fleetchart.headline') }}
                </h2>
              </div>
              <div class="panel-body text-center">
                <p v-html="$t('texts.fleetPreview.fleetchart.text')" />
              </div>
            </Panel>
          </div>
        </div>

        <hr class="large-spacer">

        <div class="row">
          <div class="col-xs-12 col-md-4 col-md-push-4">
            <Btn
              :to="{
                name: 'signup',
                params: {
                  redirectToRoute: 'fleet-add',
                },
              }"
              size="large"
              block
            >
              {{ $t('actions.signUp') }}
            </Btn>

            <hr>

            <p class="text-center">
              {{ $t('labels.alreadyRegistered') }}
            </p>

            <Btn
              :to="{
                name: 'login',
                params: {
                  redirectToRoute: 'fleet-add',
                },
              }"
              block
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
  name: 'FleetPreview',

  components: {
    Btn,
    Panel,
  },

  mixins: [
    MetaInfo,
  ],

  methods: {
    hidePreview() {
      this.$store.dispatch('fleet/hidePreview')
    },
  },
}
</script>

<style lang="scss" scoped>
  @import 'index';
</style>
