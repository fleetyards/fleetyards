<template>
  <section class="container">
    <div class="row justify-content-lg-center">
      <div class="col-12 col-lg-8">
        <Panel>
          <div class="panel-body">
            <h1>{{ $t('headlines.impressum') }}</h1>
            <br />

            <h2>{{ $t('sublines.impressum.general') }}</h2>

            <AppContact />
            <br />

            <h2>{{ $t('sublines.impressum.thirdpartycontent') }}</h2>
            <br />
            <h3>YT Ship Images</h3>
            <p v-html="$t('texts.impressum.ytShipImages')" />
            <p>
              <a href="https://redd.it/8k18sm" target="_blank" rel="noopener">
                https://redd.it/8k18sm
              </a>
            </p>
            <br />
            <h2>{{ $t('sublines.impressum.sponsors') }}</h2>
            <h3>AppSignal</h3>
            <p>{{ $t('texts.impressum.appSignal') }}</p>
            <p>
              {{ $t('texts.impressum.visit') }}
              <a href="https://appsignal.com/" target="_blank" rel="noopener">
                appsignal.com
              </a>
            </p>
            <br />

            <h2>{{ $t('sublines.impressum.disclaimer') }}</h2>
            <p>{{ $t('texts.impressum.disclaimer.p1') }}</p>
            <p>{{ $t('texts.impressum.disclaimer.p2') }}</p>
            <p>{{ $t('texts.impressum.disclaimer.p3') }}</p>
            <br />

            <h3>{{ $t('sublines.impressum.copyright') }}:</h3>
            <p>{{ $t('texts.impressum.copyright') }}</p>
            <br />

            <h3>{{ $t('sublines.impressum.liabilityInternal') }}:</h3>
            <p>{{ $t('texts.impressum.liabilityInternal.p1') }}</p>
            <p>{{ $t('texts.impressum.liabilityInternal.p2') }}</p>

            <h3>{{ $t('sublines.impressum.liabilityExternal') }}:</h3>
            <p>{{ $t('texts.impressum.liabilityExternal') }}</p>
            <br />
          </div>
        </Panel>
      </div>
    </div>
  </section>
</template>

<script lang="ts">
import Component from 'vue-class-component'
import Vue from 'vue'

import MetaInfo from 'frontend/mixins/MetaInfo'
import Panel from 'frontend/core/components/Panel'
import AppContact from 'frontend/core/components/AppContact'

@Component({
  components: {
    Panel,
    AppContact,
  },
  mixins: [MetaInfo],
})
export default class Impressum extends Vue {}
</script>
