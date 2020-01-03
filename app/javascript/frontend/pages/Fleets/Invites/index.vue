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
        <Panel v-if="currentUser">
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
              v-if="!fleetInvites.length"
              key="empty"
              class="fade-list-item col-xs-12 flex-list-item"
            >
              <div class="flex-list-row">
                <div class="empty">
                  {{ $t('labels.blank.fleetInvites') }}
                </div>
              </div>
            </div>
            <div
              v-for="(fleet, index) in fleetInvites"
              :key="`invites-${index}`"
              class="fade-list-item col-xs-12 flex-list-item"
            >
              <div class="flex-list-row">
                <div class="fleet-name">
                  {{ fleet.name }}
                </div>
                <div class="actions">
                  <Btn
                    size="small"
                    :disabled="loading"
                    inline
                    @click.native="accept(fleet)"
                  >
                    <i class="fal fa-check" />
                    {{ $t('actions.fleet.acceptInvite') }}
                  </Btn>
                  <Btn
                    size="small"
                    variant="danger"
                    :disabled="loading"
                    inline
                    @click.native="decline(fleet)"
                  >
                    <i class="fal fa-times" />
                    {{ $t('actions.fleet.declineInvite') }}
                  </Btn>
                </div>
              </div>
            </div>
          </transition-group>
        </Panel>
      </div>
    </div>
  </section>
</template>

<script>
import { mapGetters } from 'vuex'
import MetaInfo from 'frontend/mixins/MetaInfo'
import Panel from 'frontend/components/Panel'
import Btn from 'frontend/components/Btn'

export default {
  name: 'FleetInvites',

  components: {
    Panel,
    Btn,
  },

  mixins: [
    MetaInfo,
  ],

  data() {
    return {
      loading: false,
    }
  },

  computed: {
    ...mapGetters('session', [
      'currentUser',
    ]),

    fleetInvites() {
      if (!this.currentUser) {
        return []
      }

      return this.currentUser.fleets.filter((item) => item.invitation) || []
    },
  },

  methods: {
    async accept(fleet) {
      this.loading = true

      const response = await this.$api.put(`fleets/${fleet.slug}/members/accept-invite`)

      this.loading = false

      if (!response.error) {
        this.$comlink.$emit('fleetUpdate')

        this.$success({
          text: this.$t('messages.fleet.invites.accept.success'),
        })

        this.$router.push({ name: 'fleet', params: { slug: fleet.slug } })
      } else {
        this.$alert({
          text: this.$t('messages.fleet.invites.accept.failure'),
        })
      }
    },
    async decline(fleet) {
      this.loading = true
      this.$confirm({
        text: this.$t('messages.confirm.fleet.invites.decline'),
        onConfirm: async () => {
          const response = await this.$api.put(`fleets/${fleet.slug}/members/decline-invite`)

          if (!response.error) {
            this.$comlink.$emit('fleetUpdate')

            this.$success({
              text: this.$t('messages.fleet.invites.decline.success'),
            })
          } else {
            this.$alert({
              text: this.$t('messages.fleet.invites.decline.failure'),
            })
            this.loading = false
          }
        },
        onClose: () => {
          this.loading = false
        },
      })
    },
  },
}
</script>
