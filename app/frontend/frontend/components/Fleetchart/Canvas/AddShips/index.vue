<script lang="ts">
export default {
  name: "FleetchartCanvasAddShips",
};
</script>

<script lang="ts" setup>
import { keepPreviousData } from "@tanstack/vue-query";
import debounce from "lodash.debounce";
import Btn from "@/shared/components/base/Btn/index.vue";
import FormInput from "@/shared/components/base/FormInput/index.vue";
import { useFleetchartViews } from "@/frontend/composables/useFleetchartViews";
import {
  shipGeometry,
  shipLabelOf,
  viewFor,
} from "@/frontend/components/Fleetchart/geometry";
import { useModels, type Model } from "@/services/fyApi";
import { useI18n } from "@/shared/composables/useI18n";
import { FleetchartViewpoints } from "@/shared/stores/fleetchart";

const RESULTS = "20";
const SEARCH_DELAY = 300;

const emit = defineEmits<{ add: [model: Model] }>();

const { t } = useI18n();

const search = ref("");

const query = ref("");

const applySearch = debounce((value: string) => {
  query.value = value.trim();
}, SEARCH_DELAY);

watch(search, applySearch);

onBeforeUnmount(() => {
  applySearch.cancel();
});

const { data: models, isFetching } = useModels(
  computed(() => ({
    perPage: RESULTS,
    q: { searchCont: query.value || undefined },
  })),
  { query: { placeholderData: keepPreviousData } },
);

const { viewsFor, loading } = useFleetchartViews(
  () => (models.value?.items ?? []).map(({ slug }) => slug),
  true,
);

// Only ships the chart can draw: adding one without pictures would do nothing.
const ships = computed(() =>
  (models.value?.items ?? []).flatMap((model) => {
    const entry = {
      ...model,
      media: { ...model.media, ...viewsFor(model.slug) },
    };

    if (!shipGeometry(entry, FleetchartViewpoints.PORT)) {
      return [];
    }

    return [
      {
        model,
        title: shipLabelOf(entry).title,
        image:
          viewFor(entry, FleetchartViewpoints.PORT) ??
          viewFor(entry, FleetchartViewpoints.TOP),
      },
    ];
  }),
);

const searching = computed(() => isFetching.value || loading.value);
</script>

<template>
  <section
    class="fleetchart-canvas-add-ships"
    :aria-label="t('labels.fleetchartApp.addShips')"
    data-test="fleetchart-add-ships-panel"
  >
    <FormInput
      v-model="search"
      name="fleetchart-add-ships-search"
      :label="t('labels.fleetchartApp.searchShips')"
      no-label
      :placeholder="t('labels.fleetchartApp.searchShips')"
    />

    <p class="fleetchart-canvas-add-ships__hint">
      {{ t("labels.fleetchartApp.addShipsHint") }}
    </p>

    <ul v-if="ships.length" class="fleetchart-canvas-add-ships__list">
      <li v-for="ship in ships" :key="ship.model.id">
        <Btn
          class="fleetchart-canvas-add-ships__ship"
          variant="bare"
          :data-test="`fleetchart-add-ship-${ship.model.slug}`"
          @click="emit('add', ship.model)"
        >
          <img
            v-if="ship.image"
            :src="ship.image.mediumUrl"
            alt=""
            class="fleetchart-canvas-add-ships__image"
          />
          <span>{{ ship.title }}</span>
          <i class="fa-duotone fa-plus" />
        </Btn>
      </li>
    </ul>

    <p
      v-else-if="!searching"
      class="fleetchart-canvas-add-ships__hint"
      data-test="fleetchart-add-ships-empty"
    >
      {{ t("labels.fleetchartApp.noShipsFound") }}
    </p>
  </section>
</template>

<style lang="scss" scoped>
@import "index.scss";
</style>
