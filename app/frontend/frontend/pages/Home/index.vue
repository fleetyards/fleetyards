<template>
  <div>
    <Support />
    <div class="home-screen-intro">
      <section class="container">
        <div class="row">
          <div class="col-12">
            <div class="search-form text-center">
              <h1 id="home-welcome">
                <small class="text-muted">{{ t("headlines.welcome") }}</small>
                <img
                  v-if="pride"
                  :src="require('@/images/pride/logo-home.png')"
                  class="logo"
                  width="150px"
                  height="101px"
                  alt="logo"
                />
                <img
                  v-else
                  :src="require('@/images/logo-home.png')"
                  class="logo"
                  width="150px"
                  height="101px"
                  alt="logo"
                />
                {{ t("app") }}
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
                          translation-key="search.default"
                          :no-label="true"
                          :clearable="true"
                        />
                        <Btn
                          id="search-submit"
                          :aria-label="t('labels.search')"
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
              <p v-html="t('texts.indexQuote')" />
              <footer class="blockquote-footer">
                {{ t("texts.indexQuoteSource") }}
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
            {{ t("headlines.welcomeShips") }}
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
          <Loader :loading="modelsLoading" :fixed="true" />
        </div>
        <div class="col-12 col-lg-6 relative home-images">
          <Panel>
            <h2 class="sr-only">
              {{ t("headlines.welcomeImages") }}
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
                    :to="routeForImage(image)"
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

<script lang="ts" setup>
import VueScrollTo from "vue-scrollto";
import { useRouter } from "vue-router/composables";
import Loader from "@/frontend/core/components/Loader/index.vue";
import Panel from "@/frontend/core/components/Panel/index.vue";
import TeaserPanel from "@/frontend/core/components/TeaserPanel/index.vue";
import Btn from "@/frontend/core/components/Btn/index.vue";
import FormInput from "@/frontend/core/components/Form/FormInput/index.vue";
import Support from "@/frontend/components/Support/index.vue";
import LazyImage from "@/frontend/core/components/LazyImage/index.vue";
import modelsCollection from "@/frontend/api/collections/Models";
import imagesCollection from "@/frontend/api/collections/Images";
import { useI18n } from "@/frontend/composables/useI18n";
import Store from "@/frontend/lib/Store";
import type { Image } from "@/services/fyApi";

const { t } = useI18n();

const modelsLoading = ref(false);

const imagesLoading = ref(false);

const searchQuery = ref<string | null>(null);

const showScrollDown = ref(false);

const mobile = computed(() => Store.getters.mobile);

setTimeout(() => {
  showScrollDown.value = true;
}, 2000);

const pride = computed(() => new Date().getMonth() === 5);

const router = useRouter();

const search = () => {
  if (!searchQuery.value) {
    return;
  }

  router
    .push({
      name: "search",
      query: {
        q: {
          search: searchQuery.value,
        },
      },
    })
    // eslint-disable-next-line @typescript-eslint/no-empty-function
    .catch(() => {});
};

const fetchModels = async () => {
  modelsLoading.value = true;

  await modelsCollection.latest();

  modelsLoading.value = false;
};

fetchModels();

const fetchImages = async () => {
  imagesLoading.value = true;

  await imagesCollection.random();

  imagesLoading.value = false;
};

fetchImages();

const scrollDown = () => {
  VueScrollTo.scrollTo(".home-ships");
};

const routeForImage = (image: Image) => {
  if (!image.gallery) {
    return undefined;
  }

  return {
    name: "model-images",
    params: { slug: image.gallery?.slug },
  };
};
</script>

<script lang="ts">
export default {
  name: "HomePage",
};
</script>
