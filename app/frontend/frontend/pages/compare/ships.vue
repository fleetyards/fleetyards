<script lang="ts">
export default {
  name: "CompareShipsPage",
};
</script>

<script lang="ts" setup>
import Btn from "@/shared/components/base/Btn/index.vue";
import Box from "@/shared/components/base/Box/index.vue";
import ModelFilterGroup from "@/frontend/components/base/ModelFilterGroup/index.vue";
import BreadCrumbs from "@/shared/components/BreadCrumbs/index.vue";
import TopViewRows from "@/frontend/components/Compare/Models/TopView/index.vue";
import BaseRows from "@/frontend/components/Compare/Models/Base/index.vue";
import CrewRows from "@/frontend/components/Compare/Models/Crew/index.vue";
import SpeedRows from "@/frontend/components/Compare/Models/Speed/index.vue";
import HardpointRows from "@/frontend/components/Compare/Models/Hardpoints/index.vue";
import Starship42Btn from "@/frontend/components/Starship42Btn/index.vue";
import { type Model } from "@/services/fyApi";
import { useI18n } from "@/shared/composables/useI18n";
import { useApiClient } from "@/frontend/composables/useApiClient";
import { useNavStore } from "@/frontend/stores/nav";

type CompareForm = {
  models?: string[];
};

const { t } = useI18n();

const navStore = useNavStore();

const newModel = ref<string>();

const models = ref<Model[]>([]);

const form = ref<CompareForm>({});

const erkulUrl = computed(() => {
  return "https://www.erkul.games/calculator";
});

const sortedModels = computed(() => {
  const items = JSON.parse(JSON.stringify(models.value));

  return items.sort((a: Model, b: Model) => {
    if (a.name < b.name) {
      return -1;
    }

    if (a.name > b.name) {
      return 1;
    }

    return 0;
  });
});

const selectDisabled = computed(() => {
  return models.value.length > 7;
});

const disabledTooltip = computed(() => {
  if (selectDisabled.value) {
    return t("labels.compare.enough");
  }

  return undefined;
});

const crumbs = computed(() => {
  return [
    {
      to: {
        name: "ships",
      },
      label: t("nav.ships.index"),
    },
  ];
});

onMounted(() => {
  setupForm();
  form.value.models?.forEach(async (slug) => {
    const model = await fetchModel(slug);

    models.value.push(model);
  });
});

const route = useRoute();

const setupForm = () => {
  const query = JSON.parse(JSON.stringify(route.query || {}));

  form.value = {
    models: query.models || [],
  };
};

const router = useRouter();

const update = () => {
  router
    .push({
      path: route.path,
      query: {
        models: [...(form.value.models || [])],
      },
    })
    .catch(() => {});
};

watch(
  () => newModel.value,
  (value) => {
    if (!value) {
      return;
    }

    add();
  },
);

const add = async () => {
  if (newModel.value && !form.value.models?.includes(newModel.value)) {
    const model = await fetchModel(newModel.value);

    models.value.push(model);

    form.value.models?.push(newModel.value);

    update();
  }

  newModel.value = undefined;
};

const remove = (model: Model) => {
  if (form.value.models?.includes(model.slug)) {
    const index = form.value.models.indexOf(model.slug);

    form.value.models.splice(index, 1);
  }

  if (models.value.findIndex((item) => item.slug === model.slug) >= 0) {
    const index = models.value.findIndex((item) => item.slug === model.slug);

    models.value.splice(index, 1);
  }

  update();
};

const { models: modelsService } = useApiClient();

const fetchModel = async (slug: string) => {
  const model = await modelsService.model({
    slug: slug,
  });

  const hardpoints = await modelsService.modelHardpoints({
    slug: slug,
  });

  return {
    ...model,
    hardpoints,
  };
};
</script>

<template>
  <section
    :class="{
      'nav-slim': navStore.slim,
    }"
    class="container main compare-models"
  >
    <div class="row">
      <div class="col-12">
        <div class="row">
          <div class="col-12">
            <BreadCrumbs :crumbs="crumbs" />
            <br />
            <h1 class="sr-only">
              {{ t("headlines.compare.ships") }}
            </h1>
          </div>
        </div>
        <div class="row">
          <div class="col-12">
            <div class="row compare-row compare-row-headline">
              <div class="col-12 compare-row-label">
                <ModelFilterGroup
                  v-model="newModel"
                  v-tooltip="disabledTooltip"
                  :disabled="selectDisabled"
                  :return-object="true"
                  name="new-model"
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
                    :to="{ name: 'ship', params: { slug: model.slug } }"
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
                  <h1>{{ t("headlines.compare.ships") }}</h1>
                  <p>{{ t("texts.compare.ships.info") }}</p>
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
