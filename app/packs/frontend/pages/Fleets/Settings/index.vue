<template>
  <section class="container">
    <div class="row">
      <div class="col-12 col-md-3 order-md-12">
        <ul class="tabs">
          <router-link
            v-if="canEdit"
            v-slot="{ href: linkHref, navigate }"
            :to="{ name: 'fleet-settings-fleet' }"
            :custom="true"
          >
            <li role="link" @click="navigate" @keypress.enter="navigate">
              <a :href="linkHref">{{ $t('nav.fleets.settings.fleet') }}</a>
            </li>
          </router-link>

          <router-link
            v-slot="{ href: linkHref, navigate }"
            :to="{ name: 'fleet-settings-membership' }"
            :custom="true"
          >
            <li role="link" @click="navigate" @keypress.enter="navigate">
              <a :href="linkHref">{{ $t('nav.fleets.settings.membership') }}</a>
            </li>
          </router-link>
          <li
            v-if="fleet"
            v-tooltip="leaveTooltip"
            :class="{
              disabled: canEdit || leaving,
            }"
          >
            <a @click="leave">
              <i class="fal fa-sign-out" />
              {{ $t('actions.fleet.leave', { fleet: fleet.name }) }}
            </a>
          </li>
        </ul>
      </div>
      <div class="col-12 col-md-9 order-md-1">
        <router-view />
      </div>
    </div>
  </section>
</template>

<script lang="ts">
import Vue from 'vue'
import { Component, Watch } from 'vue-property-decorator'
import { displaySuccess, displayAlert, displayConfirm } from 'frontend/lib/Noty'
import fleetsCollection from 'frontend/api/collections/Fleets'

@Component<FleetSettingsIndex>({})
export default class FleetSettingsIndex extends Vue {
  leaving: boolean = false

  collection: FleetsCollection = fleetsCollection

  get fleet(): Fleet | null {
    return this.collection.record
  }

  get leaveTooltip() {
    if (this.fleet.myFleet && this.fleet.myRole === 'admin') {
      return this.$t('texts.fleets.leaveInfo')
    }

    return null
  }

  get canEdit(): boolean {
    return this.fleet?.myRole === 'admin'
  }

  @Watch('$route')
  onRouteChange() {
    this.fetch()
  }

  mounted() {
    this.fetch()
    this.$comlink.$on('fleet-update', this.fetch)
  }

  async fetch() {
    await this.collection.findBySlug(this.$route.params.slug)
  }

  async leave() {
    if ((this.myFleet && this.myFleet.role === 'admin') || this.leaving) return

    this.leaving = true
    displayConfirm({
      text: this.$t('messages.confirm.fleet.leave'),
      onConfirm: async () => {
        const response = await this.$api.destroy(
          `fleets/${this.fleet.slug}/members/leave`
        )

        this.leaving = false

        if (!response.error) {
          this.$comlink.$emit('fleet-update')

          displaySuccess({
            text: this.$t('messages.fleet.leave.success'),
          })

          // eslint-disable-next-line @typescript-eslint/no-empty-function
          this.$router.push({ name: 'home' }).catch(() => {})
        } else {
          const { error } = response
          if (error.response && error.response.data) {
            const { data: errorData } = error.response

            displayAlert({
              text: errorData.message,
            })
          } else {
            displayAlert({
              text: this.$t('messages.fleet.leave.failure'),
            })
          }
        }
      },
      onClose: () => {
        this.leaving = false
      },
    })
  }
}
</script>
