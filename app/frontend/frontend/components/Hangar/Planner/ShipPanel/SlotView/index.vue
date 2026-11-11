<script lang="ts">
export default {
  name: "HangarPlannerSlotView",
};
</script>

<script lang="ts" setup>
import { useRouter } from "vue-router";
import { keepPreviousData } from "@tanstack/vue-query";
import debounce from "lodash.debounce";
import Btn from "@/shared/components/base/Btn/index.vue";
import {
  BtnSizesEnum,
  BtnTonesEnum,
  BtnVariantsEnum,
} from "@/shared/components/base/Btn/types";
import Chip from "@/shared/components/base/Chip/index.vue";
import { ChipStatesEnum } from "@/shared/components/base/Chip/types";
import FormInput from "@/shared/components/base/FormInput/index.vue";
import Pill from "@/shared/components/base/Pill/index.vue";
import { PillVariantsEnum } from "@/shared/components/base/Pill/types";
import RowsSkeleton from "@/shared/components/RowsSkeleton/index.vue";
import ShipName from "@/frontend/components/Hangar/Planner/ShipName/index.vue";
import { useCandidateSpecs } from "@/frontend/components/Hangar/Planner/candidateSpecs";
import { usePlanMoney } from "@/frontend/components/Hangar/Planner/format";
import { startHolder } from "@/frontend/components/Hangar/Planner/reach";
import fallbackImage from "@/images/fallback/store_image.webp";
import { useI18n } from "@/shared/composables/useI18n";
import { useAppNotifications } from "@/shared/composables/useAppNotifications";
import { useHangarPlanCache } from "@/frontend/composables/useHangarPlanCache";
import {
  type HangarPlan,
  type HangarPlanCandidate,
  type HangarPlanSlot,
  type ModelOption,
  type ModelQuery,
  HangarPlanSlotStateEnum,
  useChooseHangarPlanSlotCandidate,
  useCreateHangarPlanCandidate,
  useDestroyHangarPlanCandidate,
  useDestroyHangarPlanSlot,
  useHangarPlan,
  useHangarPlanResources,
  useModelOptions,
  useUpdateHangarPlanAcquisition,
} from "@/services/fyApi";

type Props = {
  planId: string;
  slot: HangarPlanSlot;
};

const props = defineProps<Props>();

const emit = defineEmits<{
  done: [];
  settings: [slot: HangarPlanSlot];
}>();

const PER_PAGE = "20";

const { t } = useI18n();
const { money } = usePlanMoney();
const { displayAlert } = useAppNotifications();
const { updatePlan } = useHangarPlanCache();
const router = useRouter();

// Read from the plan as it stands, so a ship added or removed shows at once.
const { data: plan } = useHangarPlan(() => props.planId);
const { data: resources } = useHangarPlanResources(() => props.planId);

const current = computed(
  () =>
    plan.value?.slots.find((entry) => entry.id === props.slot.id) ?? props.slot,
);

const undecided = computed(
  () => current.value.state === HangarPlanSlotStateEnum.UNDECIDED,
);

const { specs } = useCandidateSpecs(() => current.value.candidates);

// Side by side on the compare page, in a tab of its own so the plan stays
// where it was.
const compareHref = computed(() =>
  current.value.candidates.length > 1
    ? router.resolve({
        name: "compare",
        query: {
          models: current.value.candidates.map(
            (candidate) => candidate.model.slug,
          ),
        },
      }).href
    : undefined,
);

const meta = (candidate: HangarPlanCandidate) =>
  [
    candidate.model.manufacturerName,
    candidate.paintName,
    candidate.ownedCount
      ? t("hangarPlanner.ownedCount", { count: candidate.ownedCount })
      : undefined,
    candidate.model.onSale ? undefined : t("hangarPlanner.notOnSale"),
  ]
    .filter(Boolean)
    .join(" · ");

const busy = ref<string>();

const run = async (key: string, request: () => Promise<HangarPlan>) => {
  busy.value = key;

  try {
    const answer = await request();
    updatePlan(answer);
    return answer;
  } catch {
    displayAlert({ text: t("hangarPlanner.messages.saveFailed") });
    return undefined;
  } finally {
    busy.value = undefined;
  }
};

const choose = useChooseHangarPlanSlotCandidate();
const createCandidate = useCreateHangarPlanCandidate();
const destroyCandidate = useDestroyHangarPlanCandidate();
const destroySlot = useDestroyHangarPlanSlot();
const updateAcquisition = useUpdateHangarPlanAcquisition();

const chooseCandidate = async (candidate: HangarPlanCandidate) => {
  const answer = await run(candidate.id, () =>
    choose.mutateAsync({
      hangarPlanId: props.planId,
      id: props.slot.id,
      data: { candidateId: candidate.id },
    }),
  );
  if (answer) emit("done");
};

const removeCandidate = (candidate: HangarPlanCandidate) =>
  run(candidate.id, () =>
    destroyCandidate.mutateAsync({
      hangarPlanId: props.planId,
      id: candidate.id,
    }),
  );

const removeSlot = async () => {
  const answer = await run("slot", () =>
    destroySlot.mutateAsync({
      hangarPlanId: props.planId,
      id: props.slot.id,
    }),
  );
  if (answer) emit("done");
};

// The slot's first ship took the starts it held, before the ships added
// after it existed; each now moves to the ship it comes closest to.
const settleStarts = async (answer: HangarPlan) => {
  const candidates =
    answer.slots.find((slot) => slot.id === props.slot.id)?.candidates ?? [];

  for (const { id, startModel } of current.value.starts) {
    const holder = startModel && startHolder(candidates, startModel);
    const moved =
      holder &&
      !holder.acquisitions.some((acquisition) => acquisition.id === id);

    if (moved) {
      updatePlan(
        await updateAcquisition.mutateAsync({
          hangarPlanId: props.planId,
          id,
          data: { candidateId: holder.id },
        }),
      );
    }
  }
};

const shortlistedIds = computed(
  () =>
    new Set(current.value.candidates.map((candidate) => candidate.model.id)),
);

const candidateFor = (option: ModelOption) =>
  current.value.candidates.find(
    (candidate) => candidate.model.id === option.id,
  );

const toggle = async (option: ModelOption) => {
  const candidate = candidateFor(option);
  if (candidate) {
    await removeCandidate(candidate);
    return;
  }

  const answer = await run(option.id, () =>
    createCandidate.mutateAsync({
      hangarPlanId: props.planId,
      data: { slotId: props.slot.id, modelId: option.id },
    }),
  );
  if (answer) await settleStarts(answer);
};

const search = ref("");
const searchTerm = ref("");
const onSale = ref(false);
const inHangar = ref(false);
const page = ref(1);
const records = ref<ModelOption[]>([]);

const applySearch = debounce((value: string) => {
  searchTerm.value = value.trim();
}, 300);

watch(search, (value) => applySearch(value));

watch([searchTerm, onSale, inHangar], () => {
  page.value = 1;
});

// The slot's filters bound the catalogue; the chips narrow within them. A slot
// holds only ships the plan can get: on the store, in game, or already held or
// bought back.
const queryParams = computed(() => {
  const q: ModelQuery = {
    ...current.value.filters,
    playerOwnableEq: true,
    plannable: true,
  };

  if (searchTerm.value) q.searchCont = searchTerm.value;
  if (onSale.value) q.onSaleEq = true;
  if (inHangar.value) q.inHangar = true;

  return { page: String(page.value), perPage: PER_PAGE, q };
});

const { data, isFetching, isLoading } = useModelOptions(queryParams, {
  query: { refetchOnWindowFocus: false, placeholderData: keepPreviousData },
});

watch(
  data,
  (response) => {
    if (!response) return;

    if ((response.meta.pagination?.currentPage ?? 1) <= 1) {
      records.value = response.items;
      return;
    }

    const existing = new Set(records.value.map((item) => item.id));
    records.value = [
      ...records.value,
      ...response.items.filter((item) => !existing.has(item.id)),
    ];
  },
  { immediate: true },
);

const totalCount = computed(
  () => data.value?.meta.pagination?.totalCount ?? records.value.length,
);

const hasMore = computed(
  () => page.value < (data.value?.meta.pagination?.totalPages ?? 1),
);

// Price and cargo come from the plan's own list of store ships, where the
// ship is one; the catalogue's options carry neither.
const storeModel = (id: string) =>
  resources.value?.storeModels.find((model) => model.id === id);

const facts = (option: ModelOption) => {
  const model = storeModel(option.id);

  return [
    option.classificationLabel,
    model?.cargo ? `${model.cargo} SCU` : undefined,
    model?.crew
      ? t("hangarPlanner.panel.crew", { count: model.crew })
      : undefined,
  ]
    .filter(Boolean)
    .join(" · ");
};

const hasFilters = computed(() =>
  Object.values(current.value.filters ?? {}).some((value) =>
    Array.isArray(value)
      ? value.length > 0
      : value !== undefined && value !== null,
  ),
);
</script>

<template>
  <div class="panel-view" data-test="hangar-plan-slot-view">
    <div class="panel-view__body">
      <p class="panel-view__muted">
        {{
          undecided
            ? t("hangarPlanner.chooseHint")
            : current.candidates.length
              ? t("hangarPlanner.panel.shortlistHint")
              : t("hangarPlanner.openSlotHint")
        }}
      </p>

      <section
        v-if="current.candidates.length"
        class="slot-view__shortlist"
        data-test="hangar-plan-slot-shortlist"
      >
        <header class="slot-view__head">
          <h3 class="panel-view__label">
            {{ t("hangarPlanner.panel.shortlist") }} ·
            {{ current.candidates.length }}
          </h3>
          <Btn
            v-if="compareHref"
            :href="compareHref"
            :variant="BtnVariantsEnum.BARE"
            :size="BtnSizesEnum.XS"
            target="_blank"
            data-test="hangar-plan-slot-ships-compare"
          >
            <i class="fa-light fa-code-compare" />
            {{ t("actions.compare.ships") }}
          </Btn>
        </header>
        <ul class="slot-view__compare">
          <li
            v-for="candidate in current.candidates"
            :key="candidate.id"
            class="slot-view__ship"
            data-test="hangar-plan-slot-ship"
          >
            <img
              :src="candidate.model.image?.smallUrl || fallbackImage"
              alt=""
              class="slot-view__image"
              loading="lazy"
            />
            <div class="slot-view__title">
              <span>
                <strong><ShipName :ship="candidate.model" /></strong>
                <span v-if="meta(candidate)" class="panel-view__muted">
                  {{ meta(candidate) }}
                </span>
              </span>
              <Btn
                :size="BtnSizesEnum.XS"
                :variant="BtnVariantsEnum.BARE"
                :tone="BtnTonesEnum.DANGER"
                :disabled="!!busy"
                :aria-label="t('hangarPlanner.removeCandidate')"
                :title="t('hangarPlanner.removeCandidate')"
                data-test="hangar-plan-slot-ship-remove"
                @click="removeCandidate(candidate)"
              >
                <i class="fa-light fa-xmark" />
              </Btn>
            </div>
            <dl class="slot-view__specs">
              <div
                v-for="spec in specs(candidate)"
                :key="spec.key"
                class="slot-view__spec"
              >
                <dt>{{ t(`hangarPlanner.specs.${spec.key}`) }}</dt>
                <dd>
                  {{ spec.value }}
                  <span v-if="spec.best" class="slot-view__best">
                    {{ t("hangarPlanner.specs.best") }}
                  </span>
                </dd>
              </div>
            </dl>
            <span v-if="!candidate.matchesFilters" class="slot-view__warning">
              {{ t("hangarPlanner.outsideFilters") }}
            </span>
            <Btn
              v-if="undecided"
              :size="BtnSizesEnum.MD"
              :loading="busy === candidate.id"
              :disabled="!!busy"
              block
              class="slot-view__choose"
              data-test="hangar-plan-slot-ship-choose"
              @click="chooseCandidate(candidate)"
            >
              <i class="fa-light fa-check" />
              {{ t("hangarPlanner.choose") }}
            </Btn>
          </li>
        </ul>
      </section>

      <section
        class="slot-view__catalogue"
        data-test="hangar-plan-slot-catalogue"
      >
        <header class="slot-view__head">
          <h3 class="panel-view__label">
            {{ t("hangarPlanner.panel.addToShortlist") }}
          </h3>
          <span class="panel-view__muted">
            {{
              hasFilters
                ? t("hangarPlanner.panel.withinFilters", { count: totalCount })
                : t("hangarPlanner.panel.shipCount", { count: totalCount })
            }}
          </span>
        </header>
        <FormInput
          v-model="search"
          name="slot-catalogue-search"
          :label="t('hangarPlanner.route.search')"
          :placeholder="t('hangarPlanner.route.search')"
          icon="fa-light fa-magnifying-glass"
          no-label
          standalone
        />
        <div
          class="slot-view__chips"
          role="group"
          :aria-label="t('hangarPlanner.pick.filters')"
        >
          <Chip
            :state="onSale ? ChipStatesEnum.INCLUDED : ChipStatesEnum.NEUTRAL"
            data-test="hangar-plan-slot-filter-on-sale"
            @toggle="onSale = !onSale"
          >
            {{ t("hangarPlanner.panel.onSale") }}
          </Chip>
          <Chip
            :state="inHangar ? ChipStatesEnum.INCLUDED : ChipStatesEnum.NEUTRAL"
            data-test="hangar-plan-slot-filter-hangar"
            @toggle="inHangar = !inHangar"
          >
            {{ t("hangarPlanner.panel.inHangar") }}
          </Chip>
          <Btn
            :variant="BtnVariantsEnum.BARE"
            :size="BtnSizesEnum.XS"
            data-test="hangar-plan-slot-ships-settings"
            @click="emit('settings', current)"
          >
            <i class="fa-light fa-sliders" />
            {{ t("hangarPlanner.panel.slotFilters") }}
          </Btn>
        </div>

        <RowsSkeleton v-if="isLoading && !records.length" :count="4" trailing />
        <p v-else-if="!records.length" class="panel-view__muted">
          {{ t("hangarPlanner.route.noMatch") }}
        </p>
        <ul
          v-else
          class="slot-view__rows"
          :class="{ 'slot-view__rows--fetching': isFetching }"
        >
          <li
            v-for="option in records"
            :key="option.id"
            class="slot-view__row"
            :class="{
              'slot-view__row--in': shortlistedIds.has(option.id),
            }"
            data-test="hangar-plan-slot-catalogue-row"
          >
            <img
              :src="option.media.storeImage?.smallUrl || fallbackImage"
              alt=""
              class="slot-view__thumb"
              loading="lazy"
            />
            <span class="slot-view__text">
              <strong class="slot-view__name">
                <ShipName :ship="option" />
              </strong>
              <span class="panel-view__muted slot-view__facts">
                <span>{{ option.manufacturer.name }}</span>
                <span v-if="facts(option)">{{ facts(option) }}</span>
                <Pill
                  v-if="option.inHangar"
                  :variant="PillVariantsEnum.NEUTRAL"
                >
                  {{ t("hangarPlanner.panel.inHangar") }}
                </Pill>
              </span>
            </span>
            <span v-if="storeModel(option.id)" class="slot-view__price">
              {{ money(storeModel(option.id)?.pledgePrice) }}
            </span>
            <Btn
              :size="BtnSizesEnum.SM"
              :variant="
                shortlistedIds.has(option.id)
                  ? BtnVariantsEnum.SOLID
                  : BtnVariantsEnum.GHOST
              "
              :active="shortlistedIds.has(option.id)"
              :loading="busy === option.id"
              :disabled="!!busy"
              :aria-pressed="shortlistedIds.has(option.id)"
              class="slot-view__toggle"
              data-test="hangar-plan-slot-catalogue-toggle"
              @click="toggle(option)"
            >
              <i
                :class="
                  shortlistedIds.has(option.id)
                    ? 'fa-light fa-check'
                    : 'fa-light fa-plus'
                "
              />
              {{
                shortlistedIds.has(option.id)
                  ? t("hangarPlanner.panel.shortlisted")
                  : t("hangarPlanner.panel.shortlistAdd")
              }}
            </Btn>
          </li>
        </ul>
        <Btn
          v-if="hasMore"
          :loading="isFetching"
          class="slot-view__more"
          data-test="hangar-plan-slot-catalogue-more"
          @click="page += 1"
        >
          {{ t("hangarPlanner.panel.more") }}
        </Btn>
      </section>
    </div>

    <footer class="panel-view__footer">
      <Btn
        :variant="BtnVariantsEnum.BARE"
        :tone="BtnTonesEnum.DANGER"
        :confirm="t('hangarPlanner.confirmRemoveSlot')"
        :disabled="!!busy"
        data-test="hangar-plan-slot-ships-remove-slot"
        @click="removeSlot"
      >
        <i class="fa-light fa-trash" />
        {{ t("hangarPlanner.removeSlot") }}
      </Btn>
      <Btn
        :disabled="!!busy"
        data-test="hangar-plan-slot-settings"
        @click="emit('settings', current)"
      >
        <i class="fa-light fa-sliders" />
        {{ t("hangarPlanner.slotSettings") }}
      </Btn>
    </footer>
  </div>
</template>

<style lang="scss" scoped>
@use "../view";

.slot-view__head {
  display: flex;
  flex-wrap: wrap;
  gap: 4px 12px;
  align-items: baseline;
  justify-content: space-between;
}

.slot-view__shortlist,
.slot-view__catalogue {
  display: flex;
  flex-direction: column;
  gap: 10px;
}

.slot-view__compare {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(190px, 1fr));
  gap: 10px;
  margin: 0;
  padding: 0;
  list-style: none;
}

.slot-view__ship {
  display: flex;
  flex-direction: column;
  gap: 8px;
  padding: 10px;
  border: 1px solid var(--color-edge-soft);
  border-radius: 12px;
  background: var(--color-control);
}

.slot-view__image {
  display: block;
  width: 100%;
  height: 90px;
  object-fit: cover;
  border-radius: 8px;
}

.slot-view__title {
  display: flex;
  gap: 6px;
  align-items: flex-start;
  justify-content: space-between;

  > span {
    display: flex;
    flex-direction: column;
    min-width: 0;
  }

  strong {
    color: var(--color-lifted);
  }
}

.slot-view__specs {
  margin: 0;
}

.slot-view__spec {
  display: flex;
  justify-content: space-between;
  padding: 5px 0;
  border-top: 1px solid var(--color-edge-faint);

  dt {
    font-family: "Orbitron", tahoma, sans-serif;
    font-size: 0.625rem;
    font-weight: 400;
    letter-spacing: 0.16em;
    text-transform: uppercase;
    color: var(--color-text-dim);
  }

  dd {
    margin: 0;
    font-size: 0.84375rem;
    font-weight: 600;
    color: var(--color-lifted);
  }
}

.slot-view__best {
  margin-left: 4px;
  font-size: 0.75rem;
  color: var(--color-success);
}

.slot-view__warning {
  font-size: 0.8rem;
  color: var(--color-warning);
}

.slot-view__choose {
  margin-top: auto;
}

.slot-view__chips {
  display: flex;
  flex-wrap: wrap;
  gap: 6px;
  align-items: center;
}

.slot-view__rows {
  display: flex;
  flex-direction: column;
  gap: 6px;
  margin: 0;
  padding: 0;
  list-style: none;
}

.slot-view__rows--fetching {
  opacity: 0.6;
}

.slot-view__row {
  display: flex;
  gap: 12px;
  align-items: center;
  min-height: 56px;
  padding: 6px 8px 6px 6px;
  border: 1px solid var(--color-edge-soft);
  border-radius: 12px;
  background: var(--color-control);
}

.slot-view__row--in {
  border-color: var(--color-primary);
}

.slot-view__thumb {
  flex: none;
  width: 64px;
  height: 40px;
  object-fit: cover;
  border-radius: 6px;
}

.slot-view__text {
  display: flex;
  flex: 1;
  flex-direction: column;
  gap: 2px;
  min-width: 0;
}

.slot-view__name {
  color: var(--color-lifted);
}

.slot-view__facts {
  display: flex;
  flex-wrap: wrap;
  gap: 4px 8px;
  align-items: center;
}

.slot-view__price {
  font-weight: 600;
  color: var(--color-lifted);
  white-space: nowrap;
}

.slot-view__toggle {
  flex: none;
  min-width: 132px;
}

.slot-view__more {
  align-self: center;
}

@media (max-width: 575px) {
  .slot-view__row {
    flex-wrap: wrap;
  }

  .slot-view__toggle {
    flex: 1 1 100%;
  }
}
</style>
