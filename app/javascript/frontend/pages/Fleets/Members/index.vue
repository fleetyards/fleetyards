<template>
  <section v-if="fleet" class="container">
    <div class="row">
      <div class="col-12">
        <BreadCrumbs :crumbs="crumbs" />
      </div>
      <div class="col-8">
        <h1>
          {{ $t('headlines.fleets.members') }}
          <small v-if="collection.stats" class="text-muted">
            {{
              $t('labels.fleet.members.total', {
                count: collection.stats.total,
              })
            }}
          </small>
        </h1>
      </div>
      <div class="col-4">
        <div class="page-main-actions">
          <Btn v-if="canInvite" :inline="true" @click.native="openInviteModal">
            <i class="fal fa-plus" />
            {{ $t('actions.add') }}
          </Btn>
        </div>
      </div>
    </div>

    <FilteredList
      :collection="collection"
      :name="$route.name"
      :route-query="$route.query"
      :params="$route.params"
      :hash="$route.hash"
      :paginated="true"
    >
      <FleetMembersFilterForm slot="filter" />

      <template #default="{ records }">
        <FleetMembersList :members="records" :role="fleet.myRole" />
      </template>
    </FilteredList>

    <MemberModal v-if="fleet" ref="memberModal" :fleet="fleet" />
  </section>
</template>

<script lang="ts">
import Vue from 'vue'
import { Component } from 'vue-property-decorator'
import Panel from 'frontend/core/components/Panel'
import FilteredList from 'frontend/core/components/FilteredList'
import BreadCrumbs from 'frontend/core/components/BreadCrumbs'
import Btn from 'frontend/core/components/Btn'
import FleetMembersFilterForm from 'frontend/components/Fleets/MembersFilterForm'
import MemberModal from 'frontend/components/Fleets/MemberModal'
import Avatar from 'frontend/core/components/Avatar'
import MetaInfoMixin from 'frontend/mixins/MetaInfo'
import fleetMembersCollection from 'frontend/api/collections/FleetMembers'
import FleetMembersList from 'frontend/components/Fleets/MembersList'
import { fleetRouteGuard } from 'frontend/utils/RouteGuards'
import fleetsCollection from 'frontend/api/collections/Fleets'

@Component<FleetMembers>({
  name: 'FleetMembers',
  components: {
    Btn,
    BreadCrumbs,
    Panel,
    FilteredList,
    FleetMembersFilterForm,
    Avatar,
    MemberModal,
    FleetMembersList,
  },
  mixins: [MetaInfoMixin],
  beforeRouteEnter: fleetRouteGuard,
})
export default class FleetMemmbers extends Vue {
  collection: FleetMembersCollection = fleetMembersCollection

  get fleet() {
    return fleetsCollection.record
  }

  get metaTitle(): string {
    if (!this.fleet) {
      return null
    }

    return this.$t('title.fleets.members', { fleet: this.fleet.name })
  }

  get crumbs(): BreadCumb[] {
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

  get filters(): FleetMembersParams {
    return {
      filters: this.$route.query.q,
      slug: this.$route.params.slug,
      page: this.$route.query.page,
    }
  }

  get canInvite(): boolean {
    return ['admin', 'officer'].includes(this.fleet.myRole)
  }

  mounted() {
    this.fetchFleet()
    this.fetch()
    this.$comlink.$on('fleet-member-invited', this.fetch)
    this.$comlink.$on('fleet-member-update', this.fetch)
  }

  beforeDestroy() {
    this.$comlink.$off('fleet-member-invited')
    this.$comlink.$off('fleet-member-update')
  }

  async fetch() {
    await this.collection.findAll(this.filters)
    await this.collection.findStats(this.filters)
  }

  openInviteModal() {
    this.$refs.memberModal.open()
  }

  async fetchFleet() {
    await fleetsCollection.findBySlug(this.$route.params.slug)
  }
}
</script>
