<template>
  <section class="container">
    <div class="row">
      <div class="col-lg-12">
        <BreadCrumbs :crumbs="crumbs" />
        <h1>{{ $t('headlines.fleets.settings.membership') }}</h1>
      </div>
    </div>
    <ValidationObserver v-slot="{ handleSubmit }" :slim="true">
      <form v-if="fleet && form" @submit.prevent="handleSubmit(submit)">
        <div class="row">
          <div class="col-lg-12 col-xl-6">
            <Checkbox
              id="primary"
              v-model="form.primary"
              :label="$t('labels.fleet.members.primary')"
            />
          </div>
        </div>
        <div class="row">
          <div class="col-lg-12 col-xl-6">
            <ValidationProvider
              v-slot="{ errors }"
              vid="shipsFilter"
              rules="required"
              :name="$t('labels.fleet.members.shipsFilter.field')"
              :slim="true"
            >
              <div
                :class="{ 'has-error has-feedback': errors[0] }"
                class="form-group"
              >
                <FilterGroup
                  :key="'ships-filter'"
                  v-model="form.shipsFilter"
                  translation-key="fleet.members.shipsFilter"
                  :options="shipsFilterOptions"
                  name="shipsFilter"
                />
              </div>
            </ValidationProvider>
          </div>
          <div v-if="shipsFilterIsHangarGroup" class="col-lg-12 col-xl-6">
            <ValidationProvider
              v-slot="{ errors }"
              vid="hangarGroupId"
              rules="required"
              :name="$t('labels.fleet.members.hangarGroupId.field')"
              :slim="true"
            >
              <div
                :class="{ 'has-error has-feedback': errors[0] }"
                class="form-group"
              >
                <FilterGroup
                  :key="'hangar-group-id'"
                  v-model="form.hangarGroupId"
                  translation-key="fleet.members.hangarGroupId"
                  fetch-path="hangar-groups"
                  value-attr="id"
                  name="hangarGroupId"
                />
              </div>
            </ValidationProvider>
          </div>
        </div>
        <br />
        <Btn
          :loading="submitting"
          type="submit"
          size="large"
          data-test="fleet-save"
        >
          {{ $t('actions.save') }}
        </Btn>
      </form>
    </ValidationObserver>
  </section>
</template>

<script lang="ts">
import Vue from 'vue'
import { Component, Watch } from 'vue-property-decorator'
import BreadCrumbs from 'frontend/core/components/BreadCrumbs'
import Btn from 'frontend/core/components/Btn'
import Checkbox from 'frontend/core/components/Form/Checkbox'
import FilterGroup from 'frontend/core/components/Form/FilterGroup'
import MetaInfo from 'frontend/mixins/MetaInfo'
import { displaySuccess, displayAlert } from 'frontend/lib/Noty'
import fleetMembersCollection from 'frontend/api/collections/FleetMembers'
import { fleetRouteGuard } from 'frontend/utils/RouteGuards/Fleets'
import fleetsCollection from 'frontend/api/collections/Fleets'

@Component<FleetMembershipSettings>({
  beforeRouteEnter: fleetRouteGuard,
  components: {
    BreadCrumbs,
    Btn,
    Checkbox,
    FilterGroup,
  },
  mixins: [MetaInfo],
})
export default class FleetMembershipSettings extends Vue {
  get fleet() {
    return fleetsCollection.record
  }

  get metaTitle() {
    if (!this.fleet) {
      return null
    }

    return this.$t('title.fleets.settings', { fleet: this.fleet.name })
  }

  get crumbs() {
    if (!this.fleet) {
      return []
    }

    return [
      {
        to: {
          name: 'fleet',
          params: {
            slug: this.fleet.slug,
          },
        },

        label: this.fleet.name,
      },
    ]
  }

  get shipsFilterIsHangarGroup() {
    return this.form.shipsFilter === 'hangar_group'
  }

  get shipsFilterOptions() {
    return [
      {
        name: this.$t('labels.fleet.members.shipsFilter.values.purchased'),
        value: 'purchased',
      },
      {
        name: this.$t('labels.fleet.members.shipsFilter.values.hangar_group'),
        value: 'hangar_group',
      },
      {
        name: this.$t('labels.fleet.members.shipsFilter.values.hide'),
        value: 'hide',
      },
    ]
  }

  get membership() {
    return this.collection.record
  }

  collection: FleetMembersCollection = fleetMembersCollection

  submitting: boolean = false

  form: FleetMembershipForm = {
    primary: false,
    shipsFilter: null,
    hangarGroupId: null,
  }

  @Watch('$route')
  onRouteChange() {
    this.fetchFleet()
  }

  @Watch('fleet')
  onFleetChange() {
    this.fetch()
  }

  @Watch('shipsFilterIsHangarGroup')
  onShipsFilterChange() {
    if (!this.shipsFilterIsHangarGroup) {
      this.form.hangarGroupId = null
    }
  }

  mounted() {
    this.fetchFleet()
    this.fetch()
  }

  setupForm() {
    this.form = {
      primary: this.membership?.primary,
      shipsFilter: this.membership?.shipsFilter,
      hangarGroupId: this.membership?.hangarGroupId,
    }
  }

  async fetch() {
    await this.collection.findByFleet(this.$route.params.slug)

    this.setupForm()
  }

  async fetchFleet() {
    await fleetsCollection.findBySlug(this.$route.params.slug)
  }

  async submit() {
    this.submitting = true

    const response = await this.$api.put(
      `fleets/${this.$route.params.slug}/members`,
      this.form,
    )

    this.submitting = false

    if (!response.error) {
      displaySuccess({
        text: this.$t('messages.fleet.members.update.success'),
      })

      this.$comlink.$emit('fleet-update')
    } else {
      displayAlert({
        text: this.$t('messages.fleet.members.update.failure'),
      })
    }
  }
}
</script>
