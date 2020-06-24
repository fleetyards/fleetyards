<template>
  <div>
    <Support />
    <div class="home-screen-intro">
      <section class="container">
        <div class="row">
          <div class="col-12">
            <div class="search-form text-center">
              <h1 id="home-welcome">
                <small class="text-muted">{{ $t('headlines.welcome') }}</small>
                <img
                  :src="require(`images/logo-home.png`).default"
                  class="logo"
                  alt="logo"
                />
                {{ $t('app') }}
              </h1>
              <div class="row justify-content-md-center">
                <div class="col-12 col-lg-6">
                  <form @submit.prevent="search">
                    <div class="form-group">
                      <div class="input-group-flex">
                        <FormInput
                          id="search"
                          v-model="searchQuery"
                          size="large"
                          :autofocus="!mobile"
                          :no-label="true"
                          :clearable="true"
                        />
                        <Btn
                          id="search-submit"
                          :aria-label="$t('labels.search')"
                          size="large"
                          :inline="true"
                          @click.native="search"
                        >
                          <i class="fal fa-search" />
                        </Btn>
                      </div>
                    </div>
                  </form>
                </div>
              </div>
            </div>
          </div>
        </div>
      </section>
      <section class="container">
        <div class="row">
          <div class="col-12">
            <blockquote class="blockquote text-right">
              <p v-html="$t('texts.indexQuote')" />
              <footer class="blockquote-footer">
                {{ $t('texts.indexQuoteSource') }}
                <a
                  href="https://robertsspaceindustries.com"
                  target="_blank"
                  rel="noopener"
                >
                  robertsspaceindustries.com
                </a>
              </footer>
            </blockquote>
          </div>
        </div>
      </section>
      <transition name="fade-slow">
        <div
          v-if="showScrollDown"
          class="home-scroll-to-more"
          @click="scrollDown"
        >
          <i class="fal fa-chevron-down" />
        </div>
      </transition>
    </div>
    <section class="container">
      <div class="row">
        <div class="col-12 col-lg-6 relative home-ships">
          <h2 class="sr-only">
            {{ $t('headlines.welcomeShips') }}
          </h2>
          <transition-group
            name="fade-list"
            class="row"
            tag="div"
            :appear="true"
          >
            <div
              v-for="model in modelsCollection.records"
              :key="model.id"
              class="col-12 fade-list-item"
            >
              <TeaserPanel
                :item="model"
                :to="{
                  name: 'model',
                  params: { slug: model.slug },
                }"
                variant="text"
              />
            </div>
          </transition-group>
          <Loader :loading="modelsLoading" fixed />
        </div>
        <div class="col-12 col-lg-6 relative home-images">
          <Panel>
            <h2 class="sr-only">
              {{ $t('headlines.welcomeImages') }}
            </h2>
            <div class="panel-body images">
              <transition-group
                name="fade"
                class="row flex-center"
                tag="div"
                :appear="true"
              >
                <div
                  v-for="image in imagesCollection.records"
                  :key="image.id"
                  class="col-12 col-md-6 col-lg-6"
                >
                  <LazyImage
                    :src="image.smallUrl"
                    :alt="image.name"
                    :title="image.name"
                    :to="{
                      name: 'model-images',
                      params: { slug: image.model.slug },
                    }"
                    class="home-image image"
                  />
                </div>
              </transition-group>
              <Loader :loading="imagesLoading" />
            </div>
          </Panel>
        </div>
      </div>
    </section>
  </div>
</template>

<script lang="ts">
import Vue from 'vue'
import { Component } from 'vue-property-decorator'
import { Getter } from 'vuex-class'
import VueScrollTo from 'vue-scrollto'
import MetaInfo from 'frontend/mixins/MetaInfo'
import Loader from 'frontend/components/Loader'
import Panel from 'frontend/components/Panel'
import TeaserPanel from 'frontend/components/TeaserPanel'
import Btn from 'frontend/components/Btn'
import FormInput from 'frontend/components/Form/FormInput'
import Support from 'frontend/partials/Support'
import LazyImage from 'frontend/components/LazyImage'
import models from 'frontend/collections/Models'
import images from 'frontend/collections/Images'

@Component<Home>({
  components: {
    Loader,
    Panel,
    TeaserPanel,
    Btn,
    FormInput,
    Support,
    LazyImage,
  },
  mixins: [MetaInfo],
})
export default class Home extends Vue {
  modelsCollection: ModelsCollection = models

  imagesCollection: ImagesCollection = images

  modelsLoading: boolean = false

  imagesLoading: boolean = false

  searchQuery: string = null

  showScrollDown: boolean = false

  @Getter('mobile') mobile

  created() {
    this.fetchImages()
    this.fetchModels()

    setTimeout(() => {
      this.showScrollDown = true
    }, 2000)
  }

  search() {
    if (!this.searchQuery) {
      return
    }

    this.$router.push({
      name: 'search',
      query: {
        q: {
          search: this.searchQuery,
        },
      },
    })
  }

  async fetchModels() {
    this.modelsLoading = true
    await this.modelsCollection.latest()
    this.modelsLoading = false
  }

  async fetchImages() {
    this.imagesLoading = true
    await this.imagesCollection.random()
    this.imagesLoading = false
  }

  scrollDown() {
    VueScrollTo.scrollTo('.home-ships')
  }
}
</script>
