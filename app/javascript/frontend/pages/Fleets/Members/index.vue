<template>
  <section class="container">
    <div class="row">
      <div class="col-xs-12">
        <BreadCrumbs :crumbs="crumbs" />
      </div>
    </div>
    <div class="row">
      <div class="col-xs-8">
        <h1>
          {{ $t('headlines.fleets.members') }}
          <small v-if="fleetCount">
            {{ $t('labels.fleet.members.total', { count: fleetCount.total }) }}
          </small>
        </h1>
      </div>
      <div class="col-xs-4">
        <div class="page-main-actions">
          <Btn
            inline
            @click.native="openInviteModal"
          >
            <i class="fal fa-plus" />
            {{ $t('actions.add') }}
          </Btn>
        </div>
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
                <div class="username">
                  <router-link :to="sortByUsername">
                    {{ $t('labels.username') }}
                  </router-link>
                </div>
                <div class="role" />
                <div class="joined">
                  {{ $t('labels.fleet.members.invited') }} / {{ $t('labels.fleet.members.joined') }}
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
                  <template v-if="member.invitation">
                    {{ $t('labels.fleet.members.invitation') }}
                  </template>
                  <span
                    v-else-if="member.declinedAt"
                    class="text-danger"
                  >
                    {{ $t('labels.fleet.members.declined') }}
                  </span>
                  <template v-else>
                    {{ member.roleLabel }}
                  </template>
                </div>
                <div class="joined">
                  <template v-if="member.invitation || member.declinedAt">
                    {{ member.inviteSentAtLabel }}
                  </template>
                  <template v-else>
                    {{ member.acceptedAtLabel }}
                  </template>
                </div>
                <div class="actions">
                  <Btn
                    v-if="member.role !== 'admin' && !member.invitation && !member.declinedAt"
                    size="small"
                    :disabled="!canEdit(member)"
                    inline
                    @click.native="promoteMember(Member)"
                  >
                    <i class="fal fa-chevron-up" />
                  </Btn>
                  <Btn
                    v-if="member.role !== 'member' && !member.invitation && !member.declinedAt"
                    size="small"
                    :disabled="!canEdit(member)"
                    inline
                    @click.native="demoteMember(member)"
                  >
                    <i class="fal fa-chevron-down" />
                  </Btn>
                  <Btn
                    size="small"
                    :disabled="!canEdit(member) || deleting"
                    inline
                    @click.native="removeMember(member)"
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

    <MemberModal
      v-if="fleet"
      ref="memberModal"
      :fleet="fleet"
    />
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
import MemberModal from 'frontend/partials/Fleets/MemberModal'
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
    MemberModal,
  },

  mixins: [
    MetaInfo,
    Pagination,
    Filters,
  ],

  data() {
    return {
      loading: false,
      deleting: false,
      fleet: null,
      members: [],
      invitations: [],
      fleetCount: null,
      sort: null,
    }
  },

  computed: {
    ...mapGetters('session', [
      'currentUser',
    ]),

    sortByUsername() {
      const currentSort = (this.$route.query.q || {}).sorts

      const sorts = []
      if (Array.isArray(currentSort)) {
        if (currentSort.includes('user_username asc')) {
          sorts.push('user_username desc')
        } else if (!currentSort.includes('user_username asc') && !currentSort.includes('user_username desc')) {
          sorts.push('user_username asc')
        }
      } else {
        sorts.push('user_username asc')
      }

      return {
        name: this.$route.name,
        params: this.$route.params,
        query: {
          ...this.$route.query,
          q: {
            ...this.$route.query?.q,
            sorts,
          },
        },
      }
    },

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
    this.$comlink.$on('fleetMemberInvited', this.fetch)
  },

  beforeDestroy() {
    this.$comlink.$off('fleetMemberInvited')
  },

  methods: {
    canEdit(member) {
      if (!this.currentUser) {
        return false
      }

      return this.fleet && this.fleet.role === 'admin' && member.username !== this.currentUser.username
    },

    openInviteModal() {
      this.$refs.memberModal.open()
    },

    fetch() {
      this.fetchFleet()
      this.fetchMembers()
      this.fetchFleetCount()
    },

    async removeMember(member) {
      this.deleting = true
      this.$confirm({
        text: this.$t('messages.confirm.fleet.members.destroy'),
        onConfirm: async () => {
          const response = await this.$api.destroy(`fleets/${this.$route.params.slug}/members/${member.username}`)

          if (!response.error) {
            this.$success({
              text: this.$t('messages.fleet.members.destroy.success'),
            })

            this.fetch()
          } else {
            this.$alert({
              text: this.$t('messages.fleet.members.destroy.failure'),
            })
            this.deleting = false
          }
        },
        onClose: () => {
          this.deleting = false
        },
      })
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
