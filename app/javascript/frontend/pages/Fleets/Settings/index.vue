<template>
  <section class="container">
    <div class="row">
      <div class="col-xs-12 col-sm-3 col-sm-push-9">
        <ul class="tabs">
          <router-link
            :to="{ name: 'fleet-settings-fleet' }"
            tag="li"
          >
            <a>{{ $t('nav.fleets.settings.fleet') }}</a>
          </router-link>
          <!-- <router-link
            :to="{ name: 'fleet-settings-membership' }"
            tag="li"
          >
            <a>{{ $t('nav.fleets.settings.membership') }}</a>
          </router-link> -->
          <li
            v-if="fleet && myFleet"
            v-tooltip="leaveTooltip"
            :class="{
              disabled: myFleet.role === 'admin' || leaving
            }"
          >
            <a
              @click="leave"
            >
              <i class="fal fa-sign-out" />
              {{ $t('actions.fleet.leave', { fleet: fleet.name }) }}
            </a>
          </li>
        </ul>
      </div>
      <div class="col-xs-12 col-sm-9 col-sm-pull-3">
        <router-view
          v-if="fleet"
          :fleet="fleet"
        />
      </div>
    </div>
  </section>
</template>

<script>
import FleetsMixin from 'frontend/mixins/Fleets'

export default {
  name: 'FleetSettings',

  mixins: [FleetsMixin],

  data() {
    return {
      fleet: null,
      loading: false,
      leaving: false,
    }
  },

  computed: {
    leaveTooltip() {
      if (this.myFleet && this.myFleet.role === 'admin') {
        return this.$t('texts.fleets.leaveInfo')
      }

      return null
    },
  },

  watch: {
    $route() {
      this.fetch()
    },
  },

  mounted() {
    this.fetch()
  },

  methods: {
    async fetch() {
      if (!this.myFleet) {
        return
      }

      this.loading = true

      const response = await this.$api.get(`fleets/${this.$route.params.slug}`)

      this.loading = false

      if (!response.error) {
        this.fleet = response.data
      } else if (response.error.response && response.error.response.status === 404) {
        this.$router.replace({ name: '404' })
      }
    },

    async leave() {
      if (this.myFleet.role === 'admin' || this.leaving) return

      this.leaving = true
      this.$confirm({
        text: this.$t('messages.confirm.fleet.leave'),
        onConfirm: async () => {
          const response = await this.$api.destroy(`fleets/${this.fleet.slug}/members/leave`)

          this.leaving = false

          if (!response.error) {
            this.$comlink.$emit('fleetUpdate')

            this.$success({
              text: this.$t('messages.fleet.leave.success'),
            })

            this.$router.push({ name: 'home' })
          } else {
            const { error } = response
            if (error.response && error.response.data) {
              const { data: errorData } = error.response

              this.$alert({
                text: errorData.message,
              })
            } else {
              this.$alert({
                text: this.$t('messages.fleet.leave.failure'),
              })
            }
          }
        },
        onClose: () => {
          this.leaving = false
        },
      })
    },
  },
}
</script>
