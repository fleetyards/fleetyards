<template>
  <section class="container hangar hangar-public">
    <div v-if="user" class="row">
      <div class="col-12 col-lg-12">
        <div class="row">
          <div class="col-12" />
        </div>
        <div class="row">
          <div class="col-12 col-lg-8">
            <BreadCrumbs
              :crumbs="[
                {
                  to: {
                    name: 'hangar-public',
                    params: { slug: username },
                  },
                  label: $t('headlines.hangar.public', {
                    user: usernamePlural,
                  }),
                },
              ]"
            />
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
              <i class="fab fa-guilded" />
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
              <Starship42Btn :vehicles="collection.records" />
            </div>
          </div>
        </div>
      </div>
    </div>
    <FilteredList
      key="public-hangar-fleetchart"
      :collection="collection"
      collection-method="findAllFleetchart"
      :name="$route.name"
      :route-query="$route.query"
      :params="$route.params"
      :hash="$route.hash"
    >
      <template #actions="{ records }">
        <BtnDropdown size="small">
          <template v-if="mobile">
            <Starship42Btn
              :vehicles="records"
              size="small"
              variant="link"
              :with-icon="true"
            />

            <hr />
          </template>

          <DownloadScreenshotBtn
            element="#fleetchart"
            filename="my-hangar-fleetchart"
            size="small"
            variant="link"
          />

          <hr />

          <FleetChartStatusBtn size="small" variant="link" />
        </BtnDropdown>
      </template>

      <template #default="{ records }">
        <transition name="fade" appear>
          <div v-if="records.length" class="row justify-content-lg-center">
            <div class="col-12 col-lg-4">
              <FleetchartSlider
                :initial-scale="publicFleetchartScale"
                @change="updateScale"
              />
            </div>
          </div>
        </transition>

        <FleetchartList :items="records" :scale="publicFleetchartScale" />
      </template>
    </FilteredList>
  </section>
</template>

<script lang="ts">
import Vue from 'vue'
import { Component, Watch } from 'vue-property-decorator'
import { Getter } from 'vuex-class'
import Btn from 'frontend/core/components/Btn'
import BreadCrumbs from 'frontend/core/components/BreadCrumbs'
import BtnDropdown from 'frontend/core/components/BtnDropdown'
import Starship42Btn from 'frontend/components/Starship42Btn'
import DownloadScreenshotBtn from 'frontend/components/DownloadScreenshotBtn'
import FleetChartStatusBtn from 'frontend/components/FleetChartStatusBtn'
import FleetchartList from 'frontend/components/Fleetchart/List'
import FleetchartSlider from 'frontend/components/Fleetchart/Slider'
import ModelClassLabels from 'frontend/components/Models/ClassLabels'
import MetaInfo from 'frontend/mixins/MetaInfo'
import AddonsModal from 'frontend/components/Vehicles/AddonsModal'
import Avatar from 'frontend/core/components/Avatar'
import publicVehiclesCollection from 'frontend/api/collections/PublicVehicles'
import publicUserCollection from 'frontend/api/collections/PublicUser'
import FilteredList from 'frontend/core/components/FilteredList'

@Component<PublicHangar>({
  components: {
    Btn,
    Starship42Btn,
    BtnDropdown,
    BreadCrumbs,
    AddonsModal,
    FilteredList,
    FleetChartStatusBtn,
    DownloadScreenshotBtn,
    FleetchartList,
    ModelClassLabels,
    FleetchartSlider,
    Avatar,
  },
  mixins: [MetaInfo],
})
export default class PublicHangar extends Vue {
  loading: boolean = false

  collection: PublicVehiclesCollection = publicVehiclesCollection

  userCollection: PublicUserCollection = publicUserCollection

  @Getter('mobile') mobile

  @Getter('publicFleetchartScale', { namespace: 'hangar' })
  publicFleetchartScale

  get metaTitle() {
    return this.$t('title.hangar.public', { user: this.usernamePlural })
  }

  get username() {
    return this.$route.params.username
  }

  get user() {
    return this.userCollection.record
  }

  get filters() {
    return {
      username: this.username,
      page: this.$route.query.page,
    }
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

  @Watch('$route')
  onRouteChange() {
    this.fetch()
  }

  created() {
    this.fetch()
  }

  updateScale(value) {
    this.$store.commit('hangar/setPublicFleetchartScale', value)
  }

  toggleFleetchart() {
    this.$store.dispatch('hangar/togglePublicFleetchart')
  }

  async fetch() {
    await this.userCollection.findByUsername(this.username)
    await this.collection.findAllFleetchart(this.filters)
    await this.collection.findStatsByUsername(this.username)
  }
}
</script>
