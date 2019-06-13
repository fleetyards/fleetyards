<template>
  <section class="container">
    <div class="row">
      <div class="col-xs-12 col-md-8 col-md-offset-2">
        <Panel>
          <div class="panel-body">
            <h1>{{ $t('headlines.cookie') }}</h1>
            <p>
              With this cookie policy, we wish to inform you about the use of cookies or similar
              storage technologies (hereinafter “cookies”) on this website.
            </p>
            <br>

            <h2>Cookies used on this Site</h2>
            <table class="table">
              <thead>
                <tr>
                  <th>Name</th>
                  <th>Purpose</th>
                  <th>Term</th>
                </tr>
              </thead>
              <tbody>
                <tr>
                  <td>1P_JAR</td>
                  <td>
                    These cookies are set via embedded youtube-videos and Google Fonts.
                    They register anonymous statistical data on for example how many times the video
                    is displayed and what settings are used for playback. No sensitive data is
                    collected unless you log in to your google account, in that case your choices
                    are linked with your account, for example if you click “like” on a video.
                    For more information, read the general
                    <a
                      href="https://policies.google.com/privacy"
                      target="_blank"
                      rel="noopener"
                    >
                      Google Privacy policy
                    </a>.
                  </td>
                  <td style="white-space: nowrap;">
                    1 month
                  </td>
                </tr>
                <tr>
                  <td>CONSENT</td>
                  <td>
                    These cookies are set via embedded youtube-videos and Google Fonts.
                    They register anonymous statistical data on for example how many times the video
                    is displayed and what settings are used for playback. No sensitive data is
                    collected unless you log in to your google account, in that case your choices
                    are linked with your account, for example if you click “like” on a video.
                    For more information, read the general
                    <a
                      href="https://policies.google.com/privacy"
                      target="_blank"
                      rel="noopener"
                    >
                      Google Privacy policy
                    </a>.
                  </td>
                  <td style="white-space: nowrap;">
                    20 years and 1 month
                  </td>
                </tr>
              </tbody>
            </table>

            <br>

            <h2>Deactivation or deletion of all cookies</h2>
            <p>
              You can set your web browser in such a way that cookies are generally prevented from
              being saved to your device and/or that you are asked each time whether you are in
              agreement with cookies being enabled. You can also at any time delete cookies that
              have been enabled again. You can find out how all this works in detail via your
              browser’s help function.
            </p>
            <p>
              Please note that generally deactivating cookies may lead to functional restrictions
              on our website.
            </p>
          </div>
        </Panel>
      </div>
    </div>
  </section>
</template>

<script>
import MetaInfo from 'frontend/mixins/MetaInfo'
import Panel from 'frontend/components/Panel'

export default {
  components: {
    Panel,
  },
  mixins: [MetaInfo],
  metaInfo() {
    return this.getMetaInfo({
      title: this.$t('title.cookiePolicy'),
    })
  },
}
</script>
