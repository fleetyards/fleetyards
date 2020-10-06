<template>
  <section class="container">
    <div class="row justify-content-lg-center">
      <div class="col-12 col-lg-6">
        <h1>
          {{ $t('headlines.fleets.invites') }}
        </h1>
      </div>
    </div>
    <div class="row justify-content-lg-center">
      <div class="col-12 col-lg-6">
        <Panel>
          <transition-group
            name="fade"
            class="flex-list flex-list-users"
            tag="div"
            appear
          >
            <div key="heading" class="fade-list-item col-12 flex-list-heading">
              <div class="flex-list-row">
                <div class="fleet-name" />
                <div class="actions">
                  {{ $t('labels.actions') }}
                </div>
              </div>
            </div>
            <div
              v-for="(invite, index) in invites"
              :key="`invites-${index}`"
              class="fade-list-item col-12 flex-list-item"
            >
              <div class="flex-list-row">
                <div class="fleet-name">
                  {{ invite.fleet.name }}
                </div>
                <div class="actions">
                  <Btn
                    size="small"
                    :disabled="submitting"
                    :inline="true"
                    @click.native="accept(invite)"
                  >
                    <i class="fal fa-check" />
                    {{ $t('actions.fleet.acceptInvite') }}
                  </Btn>
                  <Btn
                    size="small"
                    variant="danger"
                    :disabled="submitting"
                    :inline="true"
                    @click.native="decline(invite)"
                  >
                    <i class="fal fa-times" />
                    {{ $t('actions.fleet.declineInvite') }}
                  </Btn>
                </div>
              </div>
            </div>
            <div
              v-if="!invites.length && !loading"
              key="empty"
              class="fade-list-item col-12 flex-list-item"
            >
              <div class="flex-list-row">
                <div class="empty">
                  {{ $t('labels.blank.fleetInvites') }}
                </div>
              </div>
            </div>
          </transition-group>
        </Panel>

        <Loader :loading="loading" fixed />
      </div>
    </div>
  </section>
</template>

<script>
import MetaInfo from 'frontend/mixins/MetaInfo'
import Panel from 'frontend/core/components/Panel'
import Loader from 'frontend/core/components/Loader'
import Btn from 'frontend/core/components/Btn'
import { displaySuccess, displayAlert, displayConfirm } from 'frontend/lib/Noty'

export default {
  name: 'FleetInvites',

  components: {
    Panel,
    Loader,
    Btn,
  },

  mixins: [MetaInfo],

  data() {
    return {
      loading: true,
      submitting: false,
      invites: [],
    }
  },

  mounted() {
    this.fetch()
  },

  methods: {
    async accept(invite) {
      this.submitting = true

      const response = await this.$api.put(
        `fleets/${invite.fleet.slug}/members/accept-invite`,
      )

      this.submitting = false

      if (!response.error) {
        this.$comlink.$emit('fleet-update')

        displaySuccess({
          text: this.$t('messages.fleet.invites.accept.success'),
        })

        this.$router.push({
          name: 'fleet',
          params: { slug: invite.fleet.slug },
        })
      } else {
        displayAlert({
          text: this.$t('messages.fleet.invites.accept.failure'),
        })
      }
    },

    async decline(invite) {
      this.submitting = true

      displayConfirm({
        text: this.$t('messages.confirm.fleet.invites.decline'),
        onConfirm: async () => {
          const response = await this.$api.put(
            `fleets/${invite.fleet.slug}/members/decline-invite`,
          )

          if (!response.error) {
            this.$comlink.$emit('fleet-update')

            displaySuccess({
              text: this.$t('messages.fleet.invites.decline.success'),
            })
          } else {
            displayAlert({
              text: this.$t('messages.fleet.invites.decline.failure'),
            })
            this.submitting = false
          }
        },
        onClose: () => {
          this.submitting = false
        },
      })
    },

    async fetch() {
      this.loading = true

      const response = await this.$api.get('fleets/invites')

      this.loading = false

      if (!response.error) {
        this.invites = response.data
      }
    },
  },
}
</script>
