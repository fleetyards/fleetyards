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

      <template v-slot:default="{ records }">
        <FleetMembersList :members="records" :role="fleet.myRole" />
      </template>
    </FilteredList>

    <MemberModal v-if="fleet" ref="memberModal" :fleet="fleet" />
  </section>
</template>

<script lang="ts">
import Vue from 'vue'
import { Component } from 'vue-property-decorator'
import Panel from 'frontend/components/Panel'
import FilteredList from 'frontend/components/FilteredList'
import BreadCrumbs from 'frontend/components/BreadCrumbs'
import Btn from 'frontend/components/Btn'
import FleetMembersFilterForm from 'frontend/partials/Fleets/MembersFilterForm'
import MemberModal from 'frontend/partials/Fleets/MemberModal'
import Avatar from 'frontend/components/Avatar'
import MetaInfoMixin from 'frontend/mixins/MetaInfo'
import fleetMembersCollection from 'frontend/collections/FleetMembers'
import FleetMembersList from 'frontend/partials/Fleets/MembersList'
import { fleetRouteGuard } from 'frontend/utils/RouteGuards'

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
  fleet: Fleet | null = null

  collection: FleetMembersCollection = fleetMembersCollection

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
    this.fetch()
    this.$comlink.$on('fleetMemberInvited', this.fetch)
    this.$comlink.$on('fleetMemberUpdate', this.fetch)
  }

  beforeDestroy() {
    this.$comlink.$off('fleetMemberInvited')
    this.$comlink.$off('fleetMemberUpdate')
  }

  async fetch() {
    await this.collection.findAll(this.filters)
    await this.collection.findStats(this.filters)
  }

  openInviteModal() {
    this.$refs.memberModal.open()
  }
}
</script>
