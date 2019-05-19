<template>
  <section class="container">
    <div class="row">
      <div class="col-xs-12 col-md-8 col-md-offset-2">
        <Panel>
          <div class="panel-body">
            <h1>{{ $t('headlines.privacy') }}</h1>
            <p>
              Below you can read about what Information we are using to provide you the services on
              Fleetyards.net. For most parts this only concerns registered Users but please read
              further to get a full overview.
            </p>
            <br>

            <h2>What Information do we use?</h2>
            <p>
              Depending on if you are a registered User or only using Fleetyards.net as a Guest we
              use more or less Information from you.
            </p>
            <br>

            <h3>As a Guest</h3>
            <p>
              As a Guest on Fleetyards.net we use your Broswer Type and Version as well as
              your Operating System and Version. This Information is only collected when an Error
              occurs on Fleetyards.net to give us an overview about what went wrong and to improve
              the experience on Fleetyards.net. We use the Third Party Service <a
                href="https://sentry.io/"
                target="_blank"
                rel="noopener"
              >
                Sentry.io
              </a> to collect and group those Errors.
            </p>
            <br>

            <h3>As a registered User</h3>
            <p>
              As a registered User on Fleetyards.net we only collect, besides the Information a
              Guest provides to us in the case of an Error, the Information you provide to us via
              the <router-link :to="{name: 'signup'}">
                Signup form
              </router-link>.
            </p>
            <br>

            <h2>Why do we need this Information?</h2>
            <p>We are collection your Information for the following reasons:</p>

            <dl class="dl-horizontal">
              <dt>
                <strong>E-mail:</strong>
              </dt>
              <dd>
                To maintain your Account, notify you and to control access to it.
              </dd>
              <dt>
                <strong>Username:</strong>
              </dt>
              <dd>
                To Display a name on your Hangar page and to address you in Notifications.
              </dd>
              <dt>
                <strong>RSI-Handle (optional):</strong>
              </dt>
              <dd>
                <p>
                  To Verify your Account with <a
                    href="https://robertsspaceindustries.com"
                    target="_blank"
                    rel="noopener"
                  >
                    robertsspaceindustries.com
                  </a> and to gather Additional Information from <a
                    href="https://robertsspaceindustries.com"
                    target="_blank"
                    rel="noopener"
                  >
                    robertsspaceindustries.com
                  </a> like:
                </p>
                <ul>
                  <li>Username</li>
                  <li>Avatar Image</li>
                  <li>Title</li>
                  <li>Enlisted Date</li>
                  <li>Citizen Record</li>
                  <li>Location</li>
                  <li>Languages</li>
                </ul>
                <br>
                These Informations are only gathered from <a
                  href="https://robertsspaceindustries.com"
                  target="_blank"
                  rel="noopener"
                >
                  robertsspaceindustries.com
                </a> when you provide us with your RSI-Handle and are not
                saved in any form on our Systems and are also not shared with any Third Parties.
              </dd>
            </dl>
            <br>

            <h2>Third parties</h2>
            <p>
              Except for the Services listed below we are not sharing any of your Information with
              Third Parties.
            </p>
            <br>

            <h3>
              <a
                href="https://www.hetzner.com/"
                target="_blank"
                rel="noopener"
              >
                Hetzner.com
              </a>
            </h3>
            <p>
              We are hosting our Website as well as the Backend Services on Root-Servers provided by
              Hetzner.
            </p>
            <br>

            <h3>
              <a
                href="https://sentry.io/"
                target="_blank"
                rel="noopener"
              >
                Sentry.io
              </a>
            </h3>
            <p>
              We use Sentry.io to track Errors and be notified if a new Error occured on the
              Website or in our Backend Services. Sentry uses your User Agent Information like
              Browser, Browser Version, Operating System and Version to group and filter Errors.
            </p>
            <br>

            <h3>
              <a
                href="https://www.mailgun.com/"
                target="_blank"
                rel="noopener"
              >
                Mailgun.com
              </a>
            </h3>
            <p>
              We use Mailgun.com to send E-mails to you. This includes all System Notification like
              E-mail Confirmation, Request Passwort Reset Link and Ship Sale Notifications.
              Mailgun.com only receives your E-mail address and only stores this Information for a
              very limited time and only to send the E-mail to you.
            </p>
            <br>

            <h3>
              <a
                href="https://aws.amazon.com/"
                target="_blank"
                rel="noopener"
              >
                AWS (Amazon Web Services)
              </a>
            </h3>
            <p>
              We use AWS S3 Service to store Backups of our Services. These Backups are only stored
              for a very limited time period and uses Industry standard Encryption technologies to
              prevent unallowed access.
            </p>
            <br>

            <h2>Your choices</h2>
            <p>
              You can opt out on Notifications on the
              <router-link :to="{name: 'settings'}">
                Settings Page
              </router-link>.
            </p>
            <p>
              You can delete your Account by clicking on the "Destroy Account" Button on the
              <router-link :to="{name: 'settings'}">
                Settings Page
              </router-link> or just contact us
              and we will delete all your Information asap.
            </p>
            <p>
              Currently you are not able to Download all your provided Information yourself, but we
              are working on a way to provide this to you. Until this is finished you can contact us
              and we will provide you with all Information we currently have stored in our Services
              asap.
            </p>
            <br>

            <h2>Contact</h2>
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
      title: this.$t('title.privacyPolicy'),
    })
  },
}
</script>
