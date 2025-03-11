<script lang="ts">
export default {
  name: "HomePage",
};
</script>

<script lang="ts" setup>
import VueScrollTo from "vue-scrollto";
import { RouteLocationRaw } from "vue-router";
import Btn from "@/shared/components/base/Btn/index.vue";
import FormInput from "@/shared/components/base/FormInput/index.vue";
import SupportBtn from "@/frontend/components/SupportBtn/index.vue";
import { useI18n } from "@/shared/composables/useI18n";
import Panel from "@/shared/components/Panel/index.vue";
import TeaserPanel from "@/shared/components/TeaserPanel/index.vue";
import LazyImage from "@/shared/components/LazyImage/index.vue";
import Loader from "@/shared/components/Loader/index.vue";
import { useMobile } from "@/shared/composables/useMobile";
import { type Image } from "@/services/fyApi";
import logo from "@/images/pride/logo-planet.png";
import { BtnSizesEnum } from "@/shared/components/base/Btn/types";
import { InputSizesEnum } from "@/shared/components/base/FormInput/types";
import {
  useImagesRandom as useImagesRandomQuery,
  useModelsLatest as useLatestModelsQuery,
} from "@/services/fyApi";

const { t } = useI18n();

const searchQuery = ref<string | undefined>();

const showScrollDown = ref(false);

const mobile = useMobile();

setTimeout(() => {
  showScrollDown.value = true;
}, 2000);

const router = useRouter();

const search = () => {
  if (!searchQuery.value) {
    return;
  }

  router.push(
    {
      name: "ships",
      query: {
        searchCont: searchQuery.value,
      },
    } as unknown as RouteLocationRaw, // HACK to make insufficient types for vue-router work
  );
};

const { isLoading: modelsLoading, data: latestModels } = useLatestModelsQuery();

const { isLoading: imagesLoading, data: randomImages } = useImagesRandomQuery();

const scrollDown = () => {
  VueScrollTo.scrollTo(".home-ships");
};

const routeForImage = (image: Image) => {
  if (!image.gallery) {
    return undefined;
  }

  return {
    name: "ship-images",
    params: { slug: image.gallery?.slug },
  };
};
</script>

<template>
  <Teleport to="#header-right">
    <SupportBtn />
  </Teleport>
  <div class="home-screen-intro">
    <section>
      <div class="row">
        <div class="col-12">
          <div class="search-form text-center">
            <h1 id="home-welcome">
              <small class="text-muted">{{ t("headlines.welcome") }}</small>
              <img
                :src="logo"
                class="logo"
                width="150"
                height="101"
                alt="logo"
              />
              {{ t("title.default") }}
            </h1>
            <div class="row justify-content-md-center">
              <div class="col-12 col-lg-6">
                <form @submit.prevent="search">
                  <div class="form-group">
                    <div class="input-group-flex">
                      <FormInput
                        v-model="searchQuery"
                        name="search"
                        :size="InputSizesEnum.LARGE"
                        :autofocus="!mobile"
                        translation-key="search.default"
                        no-label
                        clearable
                      />
                      <Btn
                        id="search-submit"
                        :aria-label="t('labels.search')"
                        :size="BtnSizesEnum.LARGE"
                        @click="search"
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
    <section>
      <div class="row">
        <div class="col-12">
          <blockquote class="blockquote text-right">
            <!-- eslint-disable-next-line vue/no-v-html -->
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
  <section>
    <div class="row">
      <div class="col-12 col-lg-6 relative home-ships">
        <h2 class="sr-only">
          {{ t("headlines.welcomeShips") }}
        </h2>
        <transition-group name="fade-list" class="row" tag="div" :appear="true">
          <div
            v-for="model in latestModels"
            :key="model.id"
            class="col-12 fade-list-item"
          >
            <TeaserPanel
              :item="model"
              :to="{
                name: 'ship',
                params: { slug: model.slug },
              }"
              level="h3"
              slim
            />
          </div>
        </transition-group>
        <Loader :loading="modelsLoading" :fixed="true" />
      </div>
      <div class="col-12 col-lg-6 relative home-images">
        <Panel inset>
          <h2 class="sr-only">
            {{ t("headlines.welcomeImages") }}
          </h2>
          <div class="images">
            <transition-group
              name="fade"
              class="row flex-center"
              tag="div"
              appear
            >
              <div
                v-for="image in randomImages"
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
</template>
