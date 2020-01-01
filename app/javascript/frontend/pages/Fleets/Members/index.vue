<template>
  <section class="container">
    <div class="row">
      <div class="col-xs-12">
        <BreadCrumbs :crumbs="crumbs" />
        <h1>
          {{ $t('headlines.fleets.members') }}
          <small v-if="fleetCount">
            {{ $t('labels.fleet.members.total', { count: fleetCount.total }) }}
          </small>
        </h1>
      </div>
    </div>
    <FilteredList>
      <Paginator
        v-if="members.length"
        slot="pagination-top"
        :page="currentPage"
        :total="totalPages"
        right
      />

      <FleetMembersFilterForm slot="filter" />

      <template slot="default">
        <Panel v-if="members.length">
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
                <div class="avatar" />
                <div class="username" />
                <div class="role">
                  {{ $t('labels.fleet.members.role') }}
                </div>
                <div class="joined">
                  {{ $t('labels.fleet.members.joined') }}
                </div>
                <div class="actions">
                  {{ $t('labels.actions') }}
                </div>
              </div>
            </div>
            <div
              v-for="(member, index) in members"
              :key="`members-${index}`"
              class="fade-list-item col-xs-12 flex-list-item"
            >
              <div class="flex-list-row">
                <div class="avatar">
                  <Avatar
                    :avatar="member.avatar"
                    size="small"
                  />
                </div>
                <div class="username">
                  {{ member.username }}
                </div>
                <div class="role">
                  {{ member.roleLabel }}
                </div>
                <div class="joined">
                  {{ $l(member.createdAt) }}
                </div>
                <div class="actions">
                  <Btn
                    v-if="member.role !== 'admin'"
                    size="small"
                    :disabled="!canEdit(member)"
                    inline
                    @click.native="promote"
                  >
                    <i class="fal fa-chevron-up" />
                  </Btn>
                  <Btn
                    v-if="member.role !== 'member'"
                    size="small"
                    :disabled="!canEdit(member)"
                    inline
                    @click.native="demote"
                  >
                    <i class="fal fa-chevron-down" />
                  </Btn>
                  <Btn
                    size="small"
                    :disabled="!canEdit(member)"
                    inline
                    @click.native="remove"
                  >
                    <i class="fad fa-trash-alt" />
                  </Btn>
                </div>
              </div>
            </div>
          </transition-group>
        </Panel>

        <EmptyBox :visible="emptyBoxVisible" />

        <Loader
          :loading="loading"
          fixed
        />
      </template>

      <Paginator
        v-if="members.length"
        slot="pagination-bottom"
        :page="currentPage"
        :total="totalPages"
        right
      />
    </FilteredList>
  </section>
</template>

<script>
import { mapGetters } from 'vuex'
import Loader from 'frontend/components/Loader'
import Panel from 'frontend/components/Panel'
import FilteredList from 'frontend/components/FilteredList'
import BreadCrumbs from 'frontend/components/BreadCrumbs'
import Btn from 'frontend/components/Btn'
import EmptyBox from 'frontend/partials/EmptyBox'
import FleetMembersFilterForm from 'frontend/partials/Fleets/MembersFilterForm'
import Avatar from 'frontend/components/Avatar'
import MetaInfo from 'frontend/mixins/MetaInfo'
import Filters from 'frontend/mixins/Filters'
import Pagination from 'frontend/mixins/Pagination'

export default {
  name: 'Fleet',

  components: {
    Btn,
    BreadCrumbs,
    Panel,
    FilteredList,
    Loader,
    EmptyBox,
    FleetMembersFilterForm,
    Avatar,
  },

  mixins: [
    MetaInfo,
    Pagination,
    Filters,
  ],

  data() {
    return {
      loading: false,
      fleet: null,
      members: [],
      fleetCount: null,
    }
  },

  computed: {
    ...mapGetters('session', [
      'currentUser',
    ]),

    metaTitle() {
      if (!this.fleet) {
        return null
      }

      return this.$t('title.fleets.members', { fleet: this.fleet.name })
    },

    emptyBoxVisible() {
      return !this.loading && !this.members.length && this.isFilterSelected
    },

    crumbs() {
      if (!this.fleet) {
        return []
      }

      return [{
        to: {
          name: 'fleet',
          params: {
            slug: this.fleet.slug,
          },
        },
        label: this.fleet.name,
      }]
    },
  },

  watch: {
    $route() {
      this.fetch()
    },

    fleet() {
      if (this.fleet.backgroundImage) {
        this.$store.commit('setBackgroundImage', this.fleet.backgroundImage)
      }
    },
  },

  mounted() {
    this.fetch()
  },

  methods: {
    canEdit(member) {
      return this.fleet.role === 'admin' && member.username !== this.currentUser.username
    },

    fetch() {
      this.fetchFleet()
      this.fetchMembers()
      this.fetchFleetCount()
    },

    async removeMember(member) {
      this.loading = true

      const response = await this.$api.delete(`fleets/${this.$route.params.slug}/members/${member.username}`)

      this.loading = false

      if (!response.error) {
        this.$success({
          text: this.$t('messages.fleet.members.delete.success'),
        })
        this.fetch()
      } else {
        this.$alert({
          text: this.$t('messages.fleet.members.delete.failure'),
        })
      }
    },

    async demoteMember(member) {
      this.loading = true

      const response = await this.$api.put(`fleets/${this.$route.params.slug}/members/${member.username}/demote`)

      this.loading = false

      if (!response.error) {
        this.$success({
          text: this.$t('messages.fleet.members.demote.success'),
        })
        this.fetch()
      } else {
        this.$alert({
          text: this.$t('messages.fleet.members.demote.failure'),
        })
      }
    },

    async promoteMember(member) {
      this.loading = true

      const response = await this.$api.put(`fleets/${this.$route.params.slug}/members/${member.username}/promote`)

      this.loading = false

      if (!response.error) {
        this.$success({
          text: this.$t('messages.fleet.members.promote.success'),
        })
        this.fetch()
      } else {
        this.$alert({
          text: this.$t('messages.fleet.members.promote.failure'),
        })
      }
    },

    async fetchFleet() {
      this.loading = true

      const response = await this.$api.get(`fleets/${this.$route.params.slug}`)

      if (!response.error) {
        this.fleet = response.data
      } else if (response.error.response && response.error.response.status === 404) {
        this.$router.replace({ name: '404' })
      }

      this.resetLoading()
    },

    async fetchMembers() {
      this.loading = true

      const response = await this.$api.get(`fleets/${this.$route.params.slug}/members`, {
        q: this.$route.query.q,
        page: this.$route.query.page,
      })

      if (!response.error) {
        this.members = response.data
      }

      this.setPages(response.meta)

      this.resetLoading()
    },

    async fetchFleetCount() {
      const response = await this.$api.get(`fleets/${this.$route.params.slug}/member-quick-stats`, {
        q: this.$route.query.q,
      })

      if (!response.error) {
        this.fleetCount = response.data
      }
    },

    resetLoading() {
      setTimeout(() => {
        this.loading = false
      }, 300)
    },
  },
}
</script>
