<template>
  <section class="container">
    <div class="row">
      <div class="col-xs-12 col-md-6 col-md-offset-3">
        <h1>
          {{ $t('headlines.fleets.invites') }}
        </h1>
      </div>
    </div>
    <div class="row">
      <div class="col-xs-12 col-md-6 col-md-offset-3">
        <Panel>
          <transition-group
            name="fade"
            class="flex-list flex-list-users"
            tag="div"
            appear
          >
            <div
              key="heading"
              class="fade-list-item col-xs-12 flex-list-heading"
            >
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
              class="fade-list-item col-xs-12 flex-list-item"
            >
              <div class="flex-list-row">
                <div class="fleet-name">
                  {{ invite.fleet.name }}
                </div>
                <div class="actions">
                  <Btn
                    size="small"
                    :disabled="submitting"
                    inline
                    @click.native="accept(invite)"
                  >
                    <i class="fal fa-check" />
                    {{ $t('actions.fleet.acceptInvite') }}
                  </Btn>
                  <Btn
                    size="small"
                    variant="danger"
                    :disabled="submitting"
                    inline
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
              class="fade-list-item col-xs-12 flex-list-item"
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
import Panel from 'frontend/components/Panel'
import Loader from 'frontend/components/Loader'
import Btn from 'frontend/components/Btn'

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
        this.$comlink.$emit('fleetUpdate')

        this.$success({
          text: this.$t('messages.fleet.invites.accept.success'),
        })

        this.$router.push({
          name: 'fleet',
          params: { slug: invite.fleet.slug },
        })
      } else {
        this.$alert({
          text: this.$t('messages.fleet.invites.accept.failure'),
        })
      }
    },

    async decline(invite) {
      this.submitting = true

      this.$confirm({
        text: this.$t('messages.confirm.fleet.invites.decline'),
        onConfirm: async () => {
          const response = await this.$api.put(
            `fleets/${invite.fleet.slug}/members/decline-invite`,
          )

          if (!response.error) {
            this.$comlink.$emit('fleetUpdate')

            this.$success({
              text: this.$t('messages.fleet.invites.decline.success'),
            })
          } else {
            this.$alert({
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
