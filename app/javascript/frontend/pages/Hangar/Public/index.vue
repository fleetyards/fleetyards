<template>
  <section class="container hangar hangar-public">
    <div v-if="user" class="row">
      <div class="col-12 col-lg-12">
        <div class="row">
          <div class="col-12" />
        </div>
        <div class="row">
          <div class="col-12 col-lg-8">
            <h1>
              <Avatar :avatar="user.avatar" />
              <span>
                {{ $t('headlines.hangar.public', { user: usernamePlural }) }}
              </span>
            </h1>
          </div>
          <div class="col-12 col-lg-4 hangar-profile-links">
            <a
              v-if="user.homepage"
              v-tooltip="$t('labels.homepage')"
              :href="user.homepage"
              target="_blank"
              rel="noopener"
            >
              <i class="fad fa-home" />
            </a>
            <a
              v-if="user.rsiHandle"
              v-tooltip="$t('nav.rsiProfile')"
              :href="
                `https://robertsspaceindustries.com/citizens/${user.rsiHandle}`
              "
              target="_blank"
              rel="noopener"
            >
              <i class="icon icon-rsi" />
            </a>
            <a
              v-if="user.guilded"
              v-tooltip="$t('labels.guilded')"
              :href="user.guilded"
              target="_blank"
              rel="noopener"
            >
              <i class="icon icon-guilded" />
            </a>
            <a
              v-if="user.discord"
              v-tooltip="$t('labels.discord')"
              :href="user.discord"
              target="_blank"
              rel="noopener"
            >
              <i class="fab fa-discord" />
            </a>
            <a
              v-if="user.youtube"
              v-tooltip="$t('labels.youtube')"
              :href="user.youtube"
              target="_blank"
              rel="noopener"
            >
              <i class="fab fa-youtube" />
            </a>
            <a
              v-if="user.twitch"
              v-tooltip="$t('labels.twitch')"
              :href="user.twitch"
              target="_blank"
              rel="noopener"
            >
              <i class="fab fa-twitch" />
            </a>
          </div>
        </div>
        <div class="row">
          <div class="col-12 col-lg-9">
            <ModelClassLabels
              v-if="collection.stats"
              :label="$t('labels.hangar')"
              :count-data="collection.stats.classifications"
            />
          </div>
          <div class="col-12 col-lg-3">
            <div v-if="!mobile" class="page-actions page-actions-right">
              <Btn
                :to="{
                  name: 'hangar-public-fleetchart',
                  params: { slug: username },
                }"
              >
                <i class="fad fa-starship" />
                {{ $t('labels.fleetchart') }}
              </Btn>
            </div>
          </div>
        </div>
        <div class="row">
          <div class="col-12">
            <Paginator
              v-if="collection.records.length"
              :page="currentPage"
              :total="totalPages"
            />
          </div>
        </div>

        <transition-group name="fade-list" class="row" tag="div" appear>
          <div
            v-for="vehicle in collection.records"
            :key="vehicle.id"
            class="col-12 col-md-6 col-xl-4 col-xxlg-2-4 fade-list-item"
          >
            <ModelPanel
              :model="vehicle.model"
              :vehicle="vehicle"
              :on-addons="showAddonsModal"
            />
          </div>
        </transition-group>
        <Loader :loading="loading" fixed />
      </div>
    </div>
    <div class="row">
      <div class="col-12">
        <Paginator
          v-if="collection.records.length"
          :page="currentPage"
          :total="totalPages"
        />
      </div>
    </div>

    <AddonsModal ref="addonsModal" />
  </section>
</template>

<script lang="ts">
import Vue from 'vue'
import { Component, Watch } from 'vue-property-decorator'
import { Getter } from 'vuex-class'
import Btn from 'frontend/core/components/Btn'
import Loader from 'frontend/core/components/Loader'
import DownloadScreenshotBtn from 'frontend/components/DownloadScreenshotBtn'
import ModelPanel from 'frontend/components/Models/Panel'
import ModelClassLabels from 'frontend/components/Models/ClassLabels'
import MetaInfo from 'frontend/mixins/MetaInfo'
import Pagination from 'frontend/mixins/Pagination'
import AddonsModal from 'frontend/components/Vehicles/AddonsModal'
import Avatar from 'frontend/core/components/Avatar'
import publicVehiclesCollection from 'frontend/api/collections/PublicVehicles'
import publicUserCollection from 'frontend/api/collections/PublicUser'

@Component<PublicHangar>({
  components: {
    Btn,
    AddonsModal,
    Loader,
    DownloadScreenshotBtn,
    ModelPanel,
    ModelClassLabels,
    Avatar,
  },
  mixins: [MetaInfo, Pagination],
})
export default class PublicHangar extends Vue {
  loading: boolean = false

  collection: PublicVehiclesCollection = publicVehiclesCollection

  userCollection: PublicUserCollection = publicUserCollection

  @Getter('mobile') mobile

  get metaTitle() {
    return this.$t('title.hangar.public', { user: this.usernamePlural })
  }

  get user() {
    return this.userCollection.record
  }

  get username() {
    return this.$route.params.user
  }

  get usernamePlural() {
    if (
      this.userTitle.endsWith('s') ||
      this.userTitle.endsWith('x') ||
      this.userTitle.endsWith('z')
    ) {
      return this.userTitle
    }

    return `${this.userTitle}'s`
  }

  get userTitle() {
    return this.username[0].toUpperCase() + this.username.slice(1)
  }

  get filters() {
    return {
      page: this.$route.query.page,
    }
  }

  @Watch('$route')
  onRouteChange() {
    this.fetch()
  }

  created() {
    this.fetch()
  }

  showAddonsModal(vehicle) {
    this.$refs.addonsModal.open(vehicle)
  }

  async fetch() {
    await this.userCollection.findByUsername(this.username)
    await this.collection.findAllByUsername(this.username, this.filters)
    await this.collection.findStatsByUsername(this.username)
  }
}
</script>
