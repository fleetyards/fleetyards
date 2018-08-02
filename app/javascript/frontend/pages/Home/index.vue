<template>
  <div>
    <div class="home-screen-intro">
      <section class="container">
        <div class="row">
          <div class="col-xs-12">
            <Panel>
              <div class="search-form text-center">
                <h1>
                  <small>{{ t('headlines.welcome') }}</small>
                  {{ t('app') }}
                </h1>
                <div class="row">
                  <div class="col-xs-12 col-md-offset-3 col-md-6">
                    <form @submit.prevent="search">
                      <div class="form-group">
                        <div class="input-group-flex">
                          <input
                            v-model="searchQuery"
                            name="search"
                            class="form-control input-lg"
                            autofocus
                          >
                          <Btn
                            large
                            @click.native="search"
                          >
                            <i class="fal fa-search" />
                          </Btn>
                        </div>
                      </div>
                    </form>
                  </div>
                </div>
                <div class="row">
                  <div class="col-xs-12 col-md-12">
                    <p>{{ t('texts.index') }}</p>
                  </div>
                </div>
                <div class="row">
                  <div class="col-xs-12">
                    <span v-html="t('texts.indexSupport', { code: 'STAR-5F32-SJZ4'})" />
                  </div>
                </div>
                <br>
                <br>
                <ExternalLink
                  url="https://paypal.me/pools/c/83jQLadz60"
                  large
                  filled
                >
                  <i class="fab fa-paypal" />
                  {{ t('actions.supportUs') }}
                </ExternalLink>
              </div>
            </Panel>
          </div>
        </div>
      </section>
      <section class="container">
        <div class="row">
          <div class="col-xs-12 col-md-8 col-md-offset-4">
            <blockquote class="pull-right">
              <p v-html="t('texts.indexQuote')"/>
              <small>
                {{ t('texts.indexQuoteSource') }}
                <a
                  href="https://robertsspaceindustries.com"
                  target="_blank"
                >
                  robertsspaceindustries.com
                </a>
              </small>
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
        <div class="col-xs-12 col-md-6 relative ships">
          <h2 class="sr-only">{{ t('headlines.welcomeShips') }}</h2>
          <transition-group
            name="fade-list"
            class="flex-row"
            tag="div"
            appear
          >
            <div
              v-for="model in models"
              :key="model.id"
              class="col-xs-12 fade-list-item"
            >
              <Panel>
                <div class="model-panel">
                  <div
                    :style="{
                      'background-image': `url(${model.storeImage})`
                    }"
                    class="model-panel-image"
                  />
                  <div class="model-panel-body">
                    <router-link :to="{name: 'model', params: { slug: model.slug }}">
                      <h3>{{ model.name }}</h3>
                      <p>
                        {{ model.description }}
                      </p>
                    </router-link>
                  </div>
                </div>
              </Panel>
            </div>
          </transition-group>
          <Loader
            v-if="modelsLoading"
            fixed
          />
        </div>
        <div class="col-xs-12 col-md-6 relative images">
          <Panel>
            <h2 class="sr-only">{{ t('headlines.welcomeImages') }}</h2>
            <div class="panel-body">
              <transition-group
                v-if="images"
                name="fade"
                tag="div"
                class="flex-row flex-center"
              >
                <div
                  v-for="(image, index) in images"
                  :key="index"
                  class="col-xs-12 col-sm-6 col-md-6"
                >
                  <router-link
                    :to="{name: 'model', params: { slug: image.model.slug }}"
                    class="thumbnail"
                  >
                    <img
                      v-lazy="image.smallUrl"
                      class="img-responsive"
                      alt="Image"
                    >
                  </router-link>
                </div>
              </transition-group>
              <Loader v-if="imagesLoading" />
            </div>
          </Panel>
        </div>
      </div>
    </section>
  </div>
</template>

<script>
import I18n from 'frontend/mixins/I18n'
import MetaInfo from 'frontend/mixins/MetaInfo'
import Loader from 'frontend/components/Loader'
import Panel from 'frontend/components/Panel'
import ExternalLink from 'frontend/components/ExternalLink'
import Btn from 'frontend/components/Btn'

export default {
  components: {
    Loader,
    Panel,
    ExternalLink,
    Btn,
  },
  mixins: [I18n, MetaInfo],
  data() {
    return {
      models: [],
      modelsLoading: false,
      images: [],
      imagesLoading: false,
      searchQuery: null,
      showScrollDown: false,
    }
  },
  created () {
    this.fetchImages()
    this.fetchModels()

    setTimeout(() => {
      this.showScrollDown = true
    }, 2000)
  },
  methods: {
    search() {
      if (!this.searchQuery) {
        return
      }
      this.$router.push({
        name: 'models',
        query: {
          q: {
            nameOrDescriptionCont: this.searchQuery,
          },
        },
      })
    },
    fetchModels() {
      this.modelsLoading = true
      this.$api.get('models/latest', {}, (args) => {
        this.modelsLoading = false
        if (!args.error) {
          this.models = args.data
        }
      })
    },
    fetchImages() {
      this.imagesLoading = true
      this.$api.get('images/random', {}, (args) => {
        this.imagesLoading = false
        if (!args.error) {
          this.images = args.data
        }
      })
    },
    scrollDown() {
      this.$scrollTo('.ships')
    },
  },
  metaInfo() {
    return this.getMetaInfo({
      title: this.t('title.home'),
    })
  },
}
</script>

<style lang="scss" scoped>
  @import "./styles/index";
</style>
