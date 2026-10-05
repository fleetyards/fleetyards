<script lang="ts">
export default {
  name: "FeatureFleetActorSearch",
};
</script>

<script lang="ts" setup>
import { fleetOptions, type FleetOption } from "@/services/fyAdminApi";
import Btn from "@/shared/components/base/Btn/index.vue";
import FormInput from "@/shared/components/base/FormInput/index.vue";
import { useI18n } from "@/shared/composables/useI18n";
import debounce from "lodash.debounce";

type Props = {
  enabledIds: string[];
  busy?: boolean;
};

const props = withDefaults(defineProps<Props>(), {
  busy: false,
});

const emit = defineEmits<{
  add: [fleet: FleetOption];
}>();

const { t } = useI18n();

const search = ref<string>();
const results = ref<FleetOption[]>([]);
const page = ref(1);
const hasMore = ref(false);
const loading = ref(false);
const searched = ref(false);

// A list on the page rather than a dropdown: the API ranks exact name or SID
// first, and a select re-sorting its options alphabetically threw that away.
let request = 0;

const load = async (nextPage: number) => {
  const term = search.value?.trim();
  const current = ++request;

  if (!term) {
    results.value = [];
    hasMore.value = false;
    searched.value = false;
    return;
  }

  loading.value = true;

  try {
    const response = await fleetOptions({
      page: String(nextPage),
      q: { search: term },
    });

    // An older search answering late must not overwrite a newer one.
    if (current !== request) return;

    results.value =
      nextPage === 1 ? response.items : [...results.value, ...response.items];
    page.value = nextPage;
    hasMore.value =
      !!response.meta?.pagination &&
      response.meta.pagination.currentPage <
        response.meta.pagination.totalPages;
    searched.value = true;
  } finally {
    if (current === request) loading.value = false;
  }
};

const onSearch = debounce(() => load(1), 300);

watch(search, () => {
  void onSearch();
});

const enabled = (fleet: FleetOption) => props.enabledIds.includes(fleet.id);
</script>

<template>
  <div class="fleet-actor-search" data-test="fleet-actor-search">
    <FormInput
      v-model="search"
      name="feature-fleet-search"
      :label="t('labels.features.fleetSearch')"
      :placeholder="t('labels.features.fleetSearch')"
      icon="fa-duotone fa-magnifying-glass"
      no-label
      clearable
    />

    <p
      v-if="searched && !loading && !results.length"
      class="text-muted"
      data-test="fleet-actor-search-empty"
    >
      {{ t("labels.features.fleetSearchEmpty", { search }) }}
    </p>

    <ul v-if="results.length" class="fleet-actor-results">
      <li
        v-for="fleet in results"
        :key="fleet.id"
        class="fleet-actor-result"
        data-test="fleet-actor-result"
      >
        <span class="fleet-actor-result-name">{{ fleet.name }}</span>
        <span class="fleet-actor-result-fid text-muted">{{ fleet.fid }}</span>
        <span
          v-if="fleet.memberCount !== undefined"
          class="fleet-actor-result-members text-muted"
        >
          {{ t("labels.features.memberCount", { count: fleet.memberCount }) }}
        </span>
        <span
          v-if="enabled(fleet)"
          class="fleet-actor-result-action text-muted"
          data-test="fleet-actor-enabled"
        >
          <i class="fa-duotone fa-check" />
          {{ t("labels.features.alreadyEnabled") }}
        </span>
        <Btn
          v-else
          class="fleet-actor-result-action"
          :disabled="busy"
          :aria-label="`${t('actions.add')} ${fleet.name}`"
          data-test="fleet-actor-add"
          @click="emit('add', fleet)"
        >
          <i class="fa-duotone fa-plus" />
          {{ t("actions.add") }}
        </Btn>
      </li>
    </ul>

    <Btn
      v-if="hasMore"
      :loading="loading"
      data-test="fleet-actor-search-more"
      @click="load(page + 1)"
    >
      {{ t("actions.loadMore") }}
    </Btn>
  </div>
</template>

<style lang="scss" scoped>
.fleet-actor-search {
  display: flex;
  flex-direction: column;
  gap: 0.75rem;
  max-width: 48rem;

  p {
    margin: 0;
  }
}

.fleet-actor-results {
  list-style: none;
  margin: 0;
  padding: 0;
}

.fleet-actor-result {
  display: grid;
  grid-template-columns: minmax(0, 2fr) minmax(0, 1fr) auto auto;
  align-items: center;
  gap: 0.75rem;
  padding: 0.25rem 0;
}

.fleet-actor-result-name,
.fleet-actor-result-fid {
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}

.fleet-actor-result-fid {
  font-family: monospace;
}

.fleet-actor-result-members {
  white-space: nowrap;
}

.fleet-actor-result-action {
  justify-self: end;
  white-space: nowrap;
}

@media (max-width: 576px) {
  .fleet-actor-result {
    grid-template-columns: minmax(0, 1fr) auto;
  }

  .fleet-actor-result-fid,
  .fleet-actor-result-members {
    grid-column: 1;
  }

  .fleet-actor-result-action {
    grid-column: 2;
    grid-row: 1;
  }
}
</style>
