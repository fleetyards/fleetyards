<template>
  <section class="container hangar">
    <div class="row">
      <div class="col-xs-12">
        <div class="row">
          <div class="col-xs-12">
            <h1 class="sr-only">
              {{ $t('headlines.hangar.preview') }}
            </h1>
          </div>
        </div>

        <div class="row">
          <div class="col-xs-12">
            <h1 class="text-center">
              Your personal Hangar requires an FleetYards.net Account
            </h1>
          </div>
        </div>

        <hr class="large-spacer">

        <div class="row">
          <div class="col-xs-12">
            <h2 class="text-center">
              What Features does the Hangar include?
            </h2>
          </div>
        </div>

        <br>

        <div class="row">
          <div class="col-xs-12 col-md-4">
            <Panel>
              <div class="panel-heading">
                <h2 class="panel-title text-center">
                  Get notified about new Ships and Sales
                </h2>
              </div>
              <div class="panel-body text-center">
                <p>
                  Get notified once a new Ship is released on robertsspaceindustries.com and never
                  miss a Sale. You can also enable Sale Notifications for Ships in your Hangar.
                </p>
              </div>
            </Panel>
          </div>
          <div class="col-xs-12 col-md-4">
            <Panel>
              <div class="panel-heading">
                <h2 class="panel-title text-center">
                  Manage your Hangar
                </h2>
              </div>
              <div class="panel-body text-center">
                <p>
                  Add Ships to your Hangar, name your Ships, mark them as purchased or
                  get notified if a Ship gets on Sale. Decide which Ship you want to show on
                  your Public Hangar. Get further Insides into your Hangar: Which Roles can
                  your Ships fulfil? How many Ships are Flight Ready? What is your main
                  Manufacturer? How much money did you spend?
                </p>
              </div>
            </Panel>
          </div>
          <div class="col-xs-12 col-md-4">
            <Panel>
              <div class="panel-heading">
                <h2 class="panel-title text-center">
                  Fleetchart and Public Hangar
                </h2>
              </div>
              <div class="panel-body text-center">
                <p>
                  View your Ships as a scaled topview Fleetchart and export it as an image. Export
                  your Ships to <a
                    href="https://starship42.com"
                    target="_blank"
                    rel="noopener"
                  >starship42.com</a> to view all your Ships in 3D. Get a Public Hangar page which
                  you can share with others, you decide what Ships will be visible on your Public
                  Hangar.
                </p>
              </div>
            </Panel>
          </div>
        </div>

        <hr class="large-spacer">

        <div class="row">
          <div class="col-xs-12 col-md-6 col-md-push-3">
            <div class="actions">
              <Btn
                :to="{
                  name: 'signup',
                  params: {
                    redirectToRoute: 'hangar',
                  },
                }"
                block
              >
                {{ $t('actions.signUp') }}
              </Btn>
              <div class="center-label">
                or
              </div>
              <Btn
                :to="{
                  name: 'login',
                  params: {
                    redirectToRoute: 'hangar',
                  },
                }"
                block
              >
                {{ $t('actions.login') }}
              </Btn>
            </div>
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

  mixins: [
    MetaInfo,
  ],
}
</script>

<style lang="scss" scoped>
  .actions {
    display: flex;
    justify-content: center;

    .center-label {
      display: block;
      width: 20%;
      text-align: center;
      margin-right: 10px;
      padding-top: 8px;
    }
  }
</style>
