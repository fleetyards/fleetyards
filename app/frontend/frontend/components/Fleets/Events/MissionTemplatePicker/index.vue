<script lang="ts">
export default {
  name: "FleetEventsMissionTemplatePicker",
};
</script>

<script lang="ts" setup>
import Modal from "@/shared/components/AppModal/Inner/index.vue";
import Btn from "@/shared/components/base/Btn/index.vue";
import Pill from "@/shared/components/base/Pill/index.vue";
import FormInput from "@/shared/components/base/FormInput/index.vue";
import {
  BtnSizesEnum,
  BtnVariantsEnum,
} from "@/shared/components/base/Btn/types";
import {
  type Fleet,
  type FleetMissionsParams,
  type Mission,
  MissionStatusEnum,
  useFleetMissions,
} from "@/services/fyApi";
import { refDebounced } from "@vueuse/core";
import { useI18n } from "@/shared/composables/useI18n";
import { useComlink } from "@/shared/composables/useComlink";
import { useMissionCover } from "@/frontend/composables/useMissionCover";

type Props = {
  fleet: Fleet;
  onPick: (mission: Mission | null) => void;
};

const props = defineProps<Props>();

const { t } = useI18n();
const comlink = useComlink();
const { resolve } = useMissionCover();

const fleetSlug = computed(() => props.fleet.slug);

const search = ref("");
const debouncedSearch = refDebounced(search, 300);

const page = ref(1);

// Published only, and asked of the server: an event is never spawned from a
// draft, and a draft filtered out here would still take a slot on the page.
const queryParams = computed<FleetMissionsParams>(() => ({
  page: String(page.value),
  q: {
    statusEq: MissionStatusEnum.PUBLISHED,
    titleCont: debouncedSearch.value || undefined,
  },
}));

const {
  data: missions,
  isLoading,
  isError,
  refetch,
} = useFleetMissions(fleetSlug, queryParams);

/*
 * Accumulated rather than replaced, the way the squadron member picker grows
 * its list. A new search starts again -- page one of a different question is
 * not page four of this one.
 */
const missionList = ref<Mission[]>([]);

// Synchronously, so the query never sees the new search with the old page.
watch(
  debouncedSearch,
  () => {
    page.value = 1;
    missionList.value = [];
  },
  { flush: "sync" },
);

watch(
  missions,
  (value) => {
    if (!value) return;

    const items = value.items ?? [];
    const held = new Set(missionList.value.map((mission) => mission.id));

    missionList.value =
      page.value === 1
        ? items
        : [...missionList.value, ...items.filter((item) => !held.has(item.id))];
  },
  { immediate: true },
);

const hasMore = computed(
  () => page.value < (missions.value?.meta?.pagination?.totalPages ?? 1),
);

// The next page's query has no data while it loads, so `hasMore` cannot tell;
// the button stays, spinning, until the page is in.
const loadingMore = computed(
  () => isLoading.value && missionList.value.length > 0,
);

const loadMore = () => {
  page.value += 1;
};

const nothingPublished = computed(
  () => !!missions.value && !missionList.value.length && !debouncedSearch.value,
);

// One row of any status, asked for only once the published list came back
// empty: it is what tells "nothing published yet" apart from "no missions".
// Both lists are the active ones, so the labels say so -- a fleet whose
// missions are all archived has none to spawn an event from either.
const { data: anyMission } = useFleetMissions(
  fleetSlug,
  { perPage: "1" },
  { query: { enabled: nothingPublished } },
);

const emptyLabel = computed(() => {
  if (debouncedSearch.value) {
    return t("labels.fleets.events.pickTemplateNoMatch");
  }

  if (anyMission.value?.items?.length) {
    return t("labels.fleets.events.pickTemplateNonePublished");
  }

  return t("labels.fleets.events.pickTemplateNoneActive");
});

const pick = (mission: Mission | null) => {
  props.onPick(mission);
  comlink.emit("close-modal");
};
</script>

<template>
  <Modal :title="t('headlines.fleets.events.pickTemplate')">
    <p class="template-picker__note">
      {{ t("labels.fleets.events.pickTemplateHint") }}
    </p>

    <FormInput
      v-model="search"
      name="mission-template-search"
      :label="t('labels.fleets.events.pickTemplateSearch')"
      :placeholder="t('labels.fleets.events.pickTemplateSearch')"
      icon="fa-light fa-magnifying-glass"
      data-test="mission-template-search"
      no-label
      clearable
    />

    <p v-if="isLoading && !missionList.length" class="template-picker__note">
      {{ t("messages.loading") }}
    </p>

    <div
      v-else-if="isError && !missions"
      class="template-picker__error"
      data-test="mission-template-error"
    >
      <span class="template-picker__note">
        {{ t("labels.fleets.events.pickTemplateLoadFailed") }}
      </span>
      <Btn
        :size="BtnSizesEnum.SM"
        data-test="mission-template-retry"
        @click="refetch()"
      >
        {{ t("actions.retry") }}
      </Btn>
    </div>

    <p
      v-else-if="!missionList.length"
      class="template-picker__note"
      data-test="mission-template-empty"
    >
      {{ emptyLabel }}
    </p>

    <div class="template-list">
      <button
        type="button"
        class="template-card template-card--clear"
        data-test="mission-template-none"
        @click="pick(null)"
      >
        <i class="fa-light fa-ban template-card__icon" />
        <div class="template-card__body">
          <strong>{{ t("labels.fleets.events.noTemplate") }}</strong>
          <span class="template-card__hint">
            {{ t("labels.fleets.events.noTemplateHint") }}
          </span>
        </div>
      </button>

      <button
        v-for="mission in missionList"
        :key="mission.id"
        type="button"
        class="template-card"
        :data-test="`mission-template-${mission.slug}`"
        @click="pick(mission)"
      >
        <div
          class="template-card__cover"
          :style="{ backgroundImage: `url(${resolve(mission)})` }"
        />
        <div class="template-card__body">
          <strong class="template-card__title">{{ mission.title }}</strong>
          <div class="template-card__meta">
            <Pill uppercase>
              {{ t(`labels.fleets.missions.categories.${mission.category}`) }}
            </Pill>
            <span v-if="mission.scenario" class="template-card__hint">
              {{ mission.scenario }}
            </span>
          </div>
          <p
            v-if="mission.description"
            class="template-card__desc template-card__hint"
          >
            {{ mission.description }}
          </p>
          <div class="template-card__stats template-card__hint">
            <span>
              <strong>{{ mission.teamCount }}</strong>
              {{ t("labels.fleets.missions.teams") }}
            </span>
            <span>
              <strong>{{ mission.shipCount }}</strong>
              {{ t("labels.fleets.missions.ships") }}
            </span>
          </div>
        </div>
      </button>
    </div>

    <div v-if="hasMore || loadingMore" class="template-picker__more">
      <Btn
        :loading="loadingMore"
        :variant="BtnVariantsEnum.BARE"
        data-test="mission-template-more"
        @click="loadMore"
      >
        {{ t("actions.loadMore") }}
      </Btn>
    </div>

    <template #footer>
      <Btn
        :size="BtnSizesEnum.LG"
        :variant="BtnVariantsEnum.BARE"
        @click="comlink.emit('close-modal')"
      >
        {{ t("actions.cancel") }}
      </Btn>
    </template>
  </Modal>
</template>

<style lang="scss" scoped>
.template-picker__note {
  color: var(--color-text-dim);
}
.template-picker__error {
  display: flex;
  align-items: center;
  gap: 12px;
  margin-bottom: 12px;
}
.template-picker__more {
  display: flex;
  justify-content: center;
  margin-top: 12px;
}
.template-list {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(260px, 1fr));
  gap: 12px;
  margin-top: 12px;
}
.template-card {
  display: flex;
  flex-direction: column;
  gap: 6px;
  text-align: left;
  padding: 0;
  background: var(--color-control);
  border: 1px solid var(--color-edge-faint);
  border-radius: var(--radius-control);
  color: var(--color-text);
  cursor: pointer;
  overflow: hidden;
  transition:
    border-color 0.15s,
    transform 0.1s;

  &:hover {
    border-color: var(--color-edge-strong);
    transform: translateY(-1px);
  }
}
.template-card--clear {
  flex-direction: row;
  align-items: center;
  gap: 12px;
  padding: 14px;
  min-height: 76px;
}
.template-card__icon {
  font-size: 1.6rem;
  color: var(--color-muted);
}
.template-card__cover {
  width: 100%;
  height: 110px;
  background-size: cover;
  background-position: center;
  background-repeat: no-repeat;
}
.template-card__body {
  padding: 10px 14px;
  display: flex;
  flex-direction: column;
  gap: 4px;
  flex: 1;
}
.template-card--clear .template-card__body {
  padding: 0;
}
.template-card__title {
  font-size: 15px;
}
.template-card__meta {
  display: flex;
  align-items: center;
  gap: 6px;
  flex-wrap: wrap;
}
.template-card__hint {
  font-size: 12px;
  color: var(--color-text-dim);
}
.template-card__desc {
  margin: 0;
  display: -webkit-box;
  -webkit-line-clamp: 2;
  -webkit-box-orient: vertical;
  overflow: hidden;
}
.template-card__stats {
  display: flex;
  gap: 14px;

  strong {
    color: var(--color-text);
  }
}
</style>
