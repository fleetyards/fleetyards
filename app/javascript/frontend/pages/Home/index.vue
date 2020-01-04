<template>
  <div>
    <Support />
    <div class="home-screen-intro">
      <section class="container">
        <div class="row">
          <div class="col-xs-12">
            <div class="search-form text-center">
              <h1 id="home-welcome">
                <small>{{ $t('headlines.welcome') }}</small>
                <img
                  :src="require(`images/logo.png`)"
                  class="logo"
                >
                {{ $t('app') }}
              </h1>
              <div class="row">
                <div class="col-xs-12 col-md-offset-3 col-md-6">
                  <form @submit.prevent="search">
                    <div class="form-group">
                      <div class="input-group-flex">
                        <FormInput
                          v-model="searchQuery"
                          :aria-label="$t('placeholders.search')"
                          data-test="home-search"
                          :placeholder="$t('placeholders.search')"
                          size="large"
                          :autofocus="!mobile"
                        />
                        <Btn
                          id="search-submit"
                          :aria-label="$t('labels.search')"
                          size="large"
                          inline
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
          <div class="col-xs-12 col-md-8 col-md-offset-4">
            <blockquote class="pull-right">
              <p v-html="$t('texts.indexQuote')" />
              <small>
                {{ $t('texts.indexQuoteSource') }}
                <a
                  href="https://robertsspaceindustries.com"
                  target="_blank"
                  rel="noopener"
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
        <div class="col-xs-12 col-md-6 relative home-ships">
          <h2 class="sr-only">
            {{ $t('headlines.welcomeShips') }}
          </h2>
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
          <Loader
            :loading="modelsLoading"
            fixed
          />
        </div>
        <div class="col-xs-12 col-md-6 relative home-images">
          <Panel>
            <h2 class="sr-only">
              {{ $t('headlines.welcomeImages') }}
            </h2>
            <div class="panel-body images">
              <transition-group
                v-if="images"
                name="fade"
                class="flex-row flex-center"
                tag="div"
                appear
              >
                <div
                  v-for="image in images"
                  :key="image.id"
                  class="col-xs-12 col-sm-6 col-md-6"
                >
                  <LazyImage
                    :src="image.smallUrl"
                    :alt="image.name"
                    :title="image.name"
                    :to="{name: 'model-images', params: { slug: image.model.slug }}"
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

<script>
import MetaInfo from 'frontend/mixins/MetaInfo'
import Loader from 'frontend/components/Loader'
import Panel from 'frontend/components/Panel'
import TeaserPanel from 'frontend/components/TeaserPanel'
import Btn from 'frontend/components/Btn'
import FormInput from 'frontend/components/Form/FormInput'
import Support from 'frontend/partials/Support'
import LazyImage from 'frontend/components/LazyImage'
import { mapGetters } from 'vuex'

export default {
  components: {
    Loader,
    Panel,
    TeaserPanel,
    Btn,
    FormInput,
    Support,
    LazyImage,
  },

  mixins: [
    MetaInfo,
  ],

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

  computed: {
    ...mapGetters([
      'mobile',
    ]),
  },

  created() {
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
        name: 'search',
        query: {
          q: {
            search: this.searchQuery,
          },
        },
      })
    },

    async fetchModels() {
      this.modelsLoading = true
      const response = await this.$api.get('models/latest')
      this.modelsLoading = false
      if (!response.error) {
        this.models = response.data
      }
    },

    async fetchImages() {
      this.imagesLoading = true
      const response = await this.$api.get('images/random')
      this.imagesLoading = false
      if (!response.error) {
        this.images = response.data
      }
    },

    scrollDown() {
      this.$scrollTo('.home-ships')
    },
  },
}
</script>

<style lang="scss" scoped>
  @import 'index';
</style>
