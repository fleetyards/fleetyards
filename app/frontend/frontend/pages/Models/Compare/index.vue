<template>
  <section
    :class="{
      'nav-slim': navSlim,
    }"
    class="container compare-models"
  >
    <div class="row">
      <div class="col-12">
        <div class="row">
          <div class="col-12">
            <BreadCrumbs :crumbs="crumbs" />
            <br />
            <h1 class="sr-only">
              {{ t("headlines.compare.models") }}
            </h1>
          </div>
        </div>
        <div class="row">
          <div class="col-12">
            <div class="row compare-row compare-row-headline">
              <div class="col-12 compare-row-label">
                <CollectionFilterGroup
                  v-model="newModel"
                  v-tooltip="disabledTooltip"
                  name="new-model"
                  :search-label="t('actions.findModel')"
                  :collection="modelsCollection"
                  value-attr="slug"
                  translation-key="compare.addModel"
                  :disabled="selectDisabled"
                  :paginated="true"
                  :searchable="true"
                  :return-object="true"
                  :no-label="true"
                  @input="add"
                />
                <Btn :href="erkulUrl" :block="true" class="erkul-link">
                  <i />
                  {{ t("labels.erkul.link") }}
                </Btn>
                <Starship42Btn
                  :items="sortedModels"
                  :with-icon="true"
                  :block="true"
                />
              </div>
              <div
                v-for="model in sortedModels"
                :key="`${model.slug}-image`"
                class="col-12 compare-row-item"
              >
                <div class="compare-image">
                  <router-link
                    :key="model.storeImage"
                    v-lazy:background-image="model.storeImage"
                    :to="{ name: 'model', params: { slug: model.slug } }"
                    :aria-label="model.name"
                    class="lazy"
                  />
                  <div
                    v-tooltip="t('labels.compare.removeModel')"
                    class="remove-model"
                    @click="remove(model)"
                  >
                    <i class="fal fa-times" />
                  </div>
                </div>
              </div>
            </div>
            <div class="row compare-row compare-row-headline sticky">
              <div class="col-12 compare-row-label" />
              <div
                v-for="model in sortedModels"
                :key="`${model.slug}-title`"
                class="col-12 compare-row-item"
              >
                <div class="text-center compare-title">
                  <strong>{{ model.name }}</strong>
                </div>
              </div>
            </div>

            <div v-if="!sortedModels.length" class="row compare-row">
              <div class="col-12">
                <Box class="info" :large="true">
                  <h1>{{ t("headlines.compare.models") }}</h1>
                  <p>{{ t("texts.compare.models.info") }}</p>
                </Box>
              </div>
            </div>
            <div class="compare-wrapper">
              <TopViewRows :models="sortedModels" />
              <BaseRows :models="sortedModels" />
              <CrewRows :models="sortedModels" />
              <SpeedRows :models="sortedModels" />
              <HardpointRows :models="sortedModels" />
            </div>
          </div>
        </div>
      </div>
    </div>
  </section>
</template>

<script lang="ts" setup>
import Btn from "@/frontend/core/components/Btn/index.vue";
import modelsCollection from "@/frontend/api/collections/Models";
import modelHardpointsCollection from "@/frontend/api/collections/ModelHardpoints";
import CollectionFilterGroup from "@/frontend/core/components/Form/CollectionFilterGroup/index.vue";
import Box from "@/frontend/core/components/Box/index.vue";
import BreadCrumbs from "@/frontend/core/components/BreadCrumbs/index.vue";
import TopViewRows from "@/frontend/components/Compare/Models/TopView/index.vue";
import BaseRows from "@/frontend/components/Compare/Models/Base/index.vue";
import CrewRows from "@/frontend/components/Compare/Models/Crew/index.vue";
import SpeedRows from "@/frontend/components/Compare/Models/Speed/index.vue";
import HardpointRows from "@/frontend/components/Compare/Models/Hardpoints/index.vue";
import Starship42Btn from "@/frontend/components/Starship42Btn/index.vue";
import { useI18n } from "@/frontend/composables/useI18n";
import { useRoute, useRouter } from "vue-router/composables";
import { storeToRefs } from "pinia";
import { useAppStore } from "@/frontend/stores/App";

const appStore = useAppStore();

const { navSlim } = storeToRefs(appStore);

type Form = {
  models?: string[];
};

interface TCompareModel extends TModel {
  hardpoints: TModelHardpoint[];
}

const { t } = useI18n();

const newModel = ref<TCompareModel | null>(null);

const models = ref<TCompareModel[]>([]);

const form = ref<Form>({});

const erkulUrl = computed(() => "https://www.erkul.games/calculator");

const sortedModels = computed(() => {
  const sortModels = JSON.parse(JSON.stringify(models.value));

  return sortModels.sort((a: TModel, b: TModel) => {
    if (a.name < b.name) {
      return -1;
    }

    if (a.name > b.name) {
      return 1;
    }

    return 0;
  });
});

const selectDisabled = computed(() => models.value.length > 7);

const disabledTooltip = computed(() => {
  if (selectDisabled.value) {
    return t("labels.compare.enough");
  }

  return null;
});

const crumbs = computed(() => [
  {
    to: {
      name: "models",
    },
    label: t("nav.models.index"),
  },
]);

watch(
  () => form.value,
  () => {
    update();
  },
  { deep: true }
);

const route = useRoute();

const setupForm = () => {
  const query = JSON.parse(JSON.stringify(route.query || {}));
  form.value = {
    models: query.models || [],
  };
};

onMounted(() => {
  setupForm();

  form.value.models?.forEach(async (slug) => {
    const model = await fetchModel(slug);
    models.value.push(model);
  });
});

const router = useRouter();

const update = () => {
  router
    .replace({
      name: route.name || "compare-models",
      query: {
        models: form.value.models,
      },
    })
    // eslint-disable-next-line @typescript-eslint/no-empty-function
    .catch(() => {});
};

const add = async () => {
  if (newModel.value && !form.value.models?.includes(newModel.value.slug)) {
    const model = await fetchModel(newModel.value.slug);
    models.value.push(model);
    form.value.models?.push(newModel.value.slug);
  }
  newModel.value = null;
};

const remove = (model: TModel) => {
  if (form.value.models?.includes(model.slug)) {
    const index = form.value.models.indexOf(model.slug);
    form.value.models?.splice(index, 1);
  }

  if (models.value.findIndex((item) => item.slug === model.slug) >= 0) {
    const index = models.value.findIndex((item) => item.slug === model.slug);
    models.value.splice(index, 1);
  }
};

const fetchModel = async (slug: string): Promise<TCompareModel> => {
  const modelResponse = await modelsCollection.findBySlug(slug);

  const hardpointResponse = await modelHardpointsCollection.findAllByModel(
    slug
  );

  return {
    ...(modelResponse as TRecordSuccessResponse<TModel>).data,
    hardpoints: (
      hardpointResponse as TCollectionSuccessResponse<TModelHardpoint>
    ).data,
  };
};
</script>

<script lang="ts">
export default {
  name: "ModelsCompare",
};
</script>
