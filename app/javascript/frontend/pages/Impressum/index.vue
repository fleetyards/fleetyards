<template>
  <section class="container">
    <div class="row">
      <div class="col-xs-12 col-md-8 col-md-offset-2">
        <Panel>
          <div class="panel-body">
            <h1>{{ t('headlines.impressum') }}</h1>
            <br>

            <h2>{{ t('sublines.impressum.general') }}</h2>

            <address>
              <dl class="dl-horizontal">
                <dd class="name">
                  FleetYards.net
                </dd>
                <dt>
                  <strong>Adresse:</strong>
                </dt>
                <dd>
                  Marten Klitzke
                  <br>
                  Lindenstraße 8b
                  <br>
                  22880 Wedel
                </dd>
                <dt>
                  <strong>E-Mail:</strong>
                </dt>
                <dd>
                  <a href="mailto:info@fleetyards.net">
                    info@fleetyards.net
                  </a>
                </dd>
              </dl>
            </address>
            <br>

            <h2>{{ t('sublines.impressum.thirdpartycontent') }}</h2>
            <br>
            <h3>YT Ship Images</h3>
            <p v-html="t('texts.impressum.ytShipImages')" />
            <p>
              <a
                href="https://redd.it/8k18sm"
                target="_blank"
                rel="noopener"
              >
                https://redd.it/8k18sm
              </a>
            </p>
            <br>

            <h2>{{ t('sublines.impressum.disclaimer') }}</h2>
            <br>
            <p>
              This is an unofficial Star Citizen fansite, not affiliated with the Cloud Imperium
              group of companies.<br>
              All content on this site not authored by its host or users are property of their
              respective owners.<br>
              Star Citizen®, Squadron 42®, Roberts Space Industries®, and Cloud Imperium®
              are registered trademarks of Cloud Imperium Rights LLC. All rights reserved.
            </p>
            <br>

            <h3>{{ t('sublines.impressum.copyright') }}:</h3>
            <p v-html="t('texts.impressum.copyright')" />
            <br>

            <h3>{{ t('sublines.impressum.liabilityInternal') }}:</h3>
            <p v-html="t('texts.impressum.liabilityInternal.paragraphOne')" />
            <p v-html="t('texts.impressum.liabilityInternal.paragraphTwo')" />
            <br>

            <h3>{{ t('sublines.impressum.liabilityExternal') }}:</h3>
            <p v-html="t('texts.impressum.liabilityExternal')" />
            <br>
          </div>
        </Panel>
      </div>
    </div>
  </section>
</template>

<script>
import I18n from 'frontend/mixins/I18n'
import MetaInfo from 'frontend/mixins/MetaInfo'
import Panel from 'frontend/components/Panel'

export default {
  components: {
    Panel,
  },
  mixins: [I18n, MetaInfo],
  metaInfo() {
    return this.getMetaInfo({
      title: this.t('title.impressum'),
    })
  },
}
</script>
