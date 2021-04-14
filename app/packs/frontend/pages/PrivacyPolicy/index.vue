<template>
  <section class="container">
    <div class="row justify-content-lg-center">
      <div class="col-12 col-lg-8">
        <Panel>
          <div class="panel-body">
            <h1>{{ $t('headlines.privacy') }}</h1>
            <Btn
              class="privacy-settings-link"
              :mobile-block="true"
              @click.native="openPrivacySettings"
            >
              {{ $t('nav.privacySettings') }}
            </Btn>
            <p>
              Below you can read about what Information we are using to provide
              you the services on {{ appName }}. For most parts this only
              concerns registered Users but please read further to get a full
              overview.
            </p>
            <br />

            <h2>What Information do we use?</h2>
            <p>
              Depending on if you are a registered User or only using
              {{ appName }} as a Guest we use more or less Information from you.
            </p>
            <br />

            <h3>As a Guest</h3>
            <p>As a Guest on {{ appName }} we collect the following data:</p>
            <ul>
              <li>Anonymised IP address</li>
              <li>Referrer URL</li>
              <li>Date and time of visit</li>
              <li>Pages visited</li>
              <li>Browser information</li>
              <li>Device information</li>
            </ul>
            <p>
              This Information helps us to optimise the user experience on
              {{ appName }}. Additionally, but only when an error occurs, the
              Browser and Device information is shared with the following third
              party service
              <a href="https://sentry.io/" target="_blank" rel="noopener">
                Sentry.io
              </a>
              to collect and group those Errors.
            </p>
            <br />

            <h3>As a registered User</h3>
            <p>
              As a registered User on {{ appName }} we only collect, besides the
              Information a Guest provides to us in the case of an Error, the
              Information you provide to us via the
              <router-link :to="{ name: 'signup' }">
                Signup form
              </router-link>
              .
            </p>
            <br />

            <h2>Why do we need this Information?</h2>
            <p>We are collection your Information for the following reasons:</p>

            <dl class="dl-horizontal">
              <dt>
                <strong>Email:</strong>
              </dt>
              <dd>
                To maintain your Account, notify you and to control access to
                it.
              </dd>
              <dt>
                <strong>Username:</strong>
              </dt>
              <dd>
                To Display a name on your Hangar page and to address you in
                Notifications.
              </dd>
            </dl>
            <br />

            <h2>Third parties</h2>
            <p>
              Except for the Services listed below we are not sharing any of
              your Information with Third Parties.
            </p>
            <br />

            <h3>
              <a href="https://www.hetzner.com/" target="_blank" rel="noopener">
                Hetzner.com
              </a>
            </h3>
            <p>
              We are hosting our Website as well as the Backend Services on
              Root-Servers provided by Hetzner.
            </p>
            <br />

            <h3>
              <a href="https://sentry.io/" target="_blank" rel="noopener">
                Sentry.io
              </a>
            </h3>
            <p>
              We use Sentry.io to track Errors and be notified if a new Error
              occured on the Website or in our Backend Services. Sentry uses
              your User Agent Information like Browser, Browser Version,
              Operating System and Version to group and filter Errors.
            </p>
            <br />

            <h3>
              <a href="https://www.mailgun.com/" target="_blank" rel="noopener">
                Mailgun.com
              </a>
            </h3>
            <p>
              We use Mailgun.com to send emails to you. This includes all System
              Notification like email Confirmation, Request Passwort Reset Link
              and Ship Sale Notifications. Mailgun.com only receives your email
              address and only stores this Information for a very limited time
              and only to send the email to you.
            </p>
            <br />

            <h3>
              <a href="https://aws.amazon.com/" target="_blank" rel="noopener">
                AWS (Amazon Web Services)
              </a>
            </h3>
            <p>
              We use AWS S3 Service to store Backups of our Services. These
              Backups are only stored for a very limited time period and uses
              Industry standard Encryption technologies to prevent unallowed
              access.
            </p>
            <br />

            <h3>
              <a href="https://www.youtube.com/" target="_blank" rel="noopener">
                Youtube
              </a>
            </h3>
            <p>
              This website, uses YouTube to embed Videos. YouTube is an Internet
              video portal that enables video publishers to set video clips and
              other users free of charge, which also provides free viewing,
              review and commenting on them. YouTube allows you to publish all
              kinds of videos, so you can access both full movies and TV
              broadcasts, as well as music videos, trailers, and videos made by
              users via the Internet portal.
            </p>
            <p>
              The operating company of YouTube is YouTube, LLC, 901 Cherry Ave.,
              San Bruno, CA 94066, United States of America. The YouTube, LLC is
              a subsidiary of Alphabet Inc. 1600 Amphitheatre Parkway, Mountain
              View, CA 94043-1351, United States of America.
            </p>
            <p>
              On pages with an embeded Video, Youtube will gather information
              like your IP address and Refarral URL. Additionally, if you are
              logged in on the Youtube homepage, Youtube will attach the
              gathered data to the logged in account.
            </p>
            <p>
              YouTube's data protection provisions, available at
              https://www.google.com/intl/en/policies/privacy/, provide
              information about the collection, processing and use of personal
              data by YouTube and Alphabet.
            </p>
            <br />

            <h2>Your choices</h2>
            <p>
              You can opt out on Notifications on the
              <router-link :to="{ name: 'settings' }">
                Settings Page
              </router-link>
              .
            </p>
            <p>
              You can delete your Account by clicking on the "Destroy Account"
              Button on the
              <router-link :to="{ name: 'settings' }">
                Settings Page
              </router-link>
              or just contact us and we will delete all your Information asap.
            </p>
            <p>
              Currently you are not able to Download all your provided
              Information yourself, but we are working on a way to provide this
              to you. Until this is finished you can contact us and we will
              provide you with all Information we currently have stored in our
              Services asap.
            </p>
            <br />

            <h2>Contact</h2>
            <AppContact />
            <br />
          </div>
        </Panel>
      </div>
    </div>
  </section>
</template>

<script lang="ts">
import Vue from 'vue'
import { Component } from 'vue-property-decorator'
import MetaInfo from 'frontend/mixins/MetaInfo'
import Panel from 'frontend/core/components/Panel'
import Btn from 'frontend/core/components/Btn'
import AppContact from 'frontend/core/components/AppContact'

@Component<PrivacyPolicy>({
  components: {
    Panel,
    Btn,
    AppContact,
  },
  mixins: [MetaInfo],
})
export default class PrivacyPolicy extends Vue {
  get appName() {
    return window.APP_NAME
  }

  openPrivacySettings() {
    this.$comlink.$emit('open-privacy-settings', true)
  }
}
</script>

<style lang="scss" scoped>
@import 'index';
</style>
