<script lang="ts">
export default {
  name: "MissionsFilterForm",
};
</script>

<script lang="ts" setup>
import BaseSelect from "@/shared/components/base/Select/index.vue";
import FormInput from "@/shared/components/base/FormInput/index.vue";
import Btn from "@/shared/components/base/Btn/index.vue";
import { InputSizesEnum } from "@/shared/components/base/FormInput/types";
import { useI18n } from "@/shared/composables/useI18n";
import { useMissionFilters } from "@/frontend/composables/useMissionFilters";
import ModelPickerSelect from "@/frontend/components/Models/PickerSelect/index.vue";
import { useMissionShip } from "@/frontend/composables/useMissionShip";
import {
  type GameMissionQuery,
  type ModelQuery,
  ModelProductionStatusEnum,
  BlueprintSourceAlignmentEnum,
  GameMissionKindEnum,
  GameMissionLocationKindEnum,
  GameMissionRewardFilterEnum,
  useFiltersGameMissionsOrgs,
  useFiltersGameMissionsStandings,
} from "@/services/fyApi";

type Props = {
  hideQuicksearch?: boolean;
};

withDefaults(defineProps<Props>(), {
  hideQuicksearch: false,
});

const { t } = useI18n();

// A single value in the URL comes back from `route.query` as a string rather
// than an array -- vue-router does no normalising -- so a multi-select handed
// one straight through gets a string where it expects a list. Every
// click-to-filter link on a row lands on exactly that case.
const asList = (value: unknown): string[] => {
  if (Array.isArray(value)) return value as string[];

  return value ? [value as string] : [];
};

const prefillFormValues = (): GameMissionQuery => ({
  nameCont: filters.value.nameCont,
  orgNameIn: asList(filters.value.orgNameIn ?? filters.value.orgNameEq),
  minStandingIn: asList(
    filters.value.minStandingIn ?? filters.value.minStandingEq,
  ),
  alignmentIn: asList(
    filters.value.alignmentIn,
  ) as BlueprintSourceAlignmentEnum[],
  kindIn: asList(
    filters.value.kindIn ?? filters.value.kindEq,
  ) as GameMissionKindEnum[],
  rewardingIn: asList(
    filters.value.rewardingIn ?? filters.value.rewarding,
  ) as GameMissionRewardFilterEnum[],
  locationKindIn: asList(
    filters.value.locationKindIn ?? filters.value.locationKindEq,
  ) as GameMissionLocationKindEnum[],
  released: filters.value.released,
});

const setupForm = () => {
  form.value = prefillFormValues();
};

const { filter, resetFilter, isFilterSelected, filters } =
  useMissionFilters(setupForm);

const form = ref<GameMissionQuery>(prefillFormValues());

watch(
  () => form.value,
  () => filter(form.value),
  { deep: true },
);

const handleSubmit = () => {
  filter(form.value);
};

// The 29 orgs that offer work in the loaded build, not the 38 the export
// declares a reputation record for -- the endpoint answers with the former.
const { data: orgs } = useFiltersGameMissionsOrgs();

// The bands missions are actually offered in. The export declares 380 standing
// records and no rank order a parse can read, so these arrive alphabetical.
const { data: standings } = useFiltersGameMissionsStandings();

const alignments = computed(() =>
  Object.values(BlueprintSourceAlignmentEnum).map((value) => ({
    value,
    label: t(`labels.gameMission.alignments.${value}`),
  })),
);

const kinds = computed(() =>
  Object.values(GameMissionKindEnum).map((value) => ({
    value,
    label: t(`labels.gameMission.kinds.${value}`),
  })),
);

// Every kind a mission can be said to pay, blueprints included -- a recipe
// comes from a reward pool rather than from a contract result, and a reader
// filtering "what do I get" should not have to know the difference.
const rewardKinds = computed(() =>
  Object.values(GameMissionRewardFilterEnum).map((value) => ({
    value,
    label: t(`labels.gameMission.rewardKinds.${value}`),
  })),
);

const locationKinds = computed(() =>
  Object.values(GameMissionLocationKindEnum).map((value) => ({
    value,
    label: t(`labels.gameMission.locationKinds.${value}`),
  })),
);

// The ship a pilot flies, which marks the contracts it can't do rather than
// hiding them. In the URL beside the filters, never sent to the API.
const { shipSlug, setShip } = useMissionShip();

// A contract is flown in a ship that exists, so concepts are left out.
const flightReady: ModelQuery = {
  productionStatusIn: [ModelProductionStatusEnum.FLIGHT_READY],
};

// Bound to the URL rather than to the form: the ship marks the list and is
// never one of the filters sent to the API.
const shipValue = computed({
  get: () => shipSlug.value,
  set: (slug?: string) => {
    void setShip(slug);
  },
});

// Three states, not a checkbox: only what the build offers, only what it does
// not, and no opinion. 349 of the 2,536 are in the middle case, and a checkbox
// could not ask for them.
const releasedOptions = computed(() => [
  { value: "true", label: t("labels.filters.missions.released") },
  { value: "false", label: t("labels.filters.missions.unreleased") },
]);

// Kept as the string the option carries, never cast to a boolean here.
// `useFilters` drops every falsy value before it builds the route, so a
// `released` of `false` would be deleted on its way out and "not in release"
// would quietly return the whole catalogue. "false" is truthy and survives,
// and the API casts it -- which is what the URL would have carried either way,
// since a query string has only strings in it.
const releasedValue = computed({
  get: () => {
    const value = form.value.released;
    if (value === undefined || value === null) return undefined;

    return String(value);
  },
  set: (value?: string) => {
    form.value = {
      ...form.value,
      released: value as unknown as boolean | undefined,
    };
  },
});
</script>

<template>
  <form @submit.prevent="handleSubmit">
    <!-- The name search belongs in the header, where every other list puts it. -->
    <Teleport v-if="!hideQuicksearch" to="#header-left">
      <FormInput
        v-model="form.nameCont"
        :size="InputSizesEnum.MEDIUM"
        name="search"
        translation-key="filters.missions.name"
        :no-label="true"
        :clearable="true"
      />
    </Teleport>

    <BaseSelect
      v-model="form.orgNameIn"
      name="org"
      :options="orgs ?? []"
      :label="t('labels.filters.missions.org')"
      :no-label="true"
      multiple
      searchable
    />

    <BaseSelect
      v-model="form.minStandingIn"
      name="standing"
      :options="standings ?? []"
      :label="t('labels.filters.missions.standing')"
      :no-label="true"
      multiple
      searchable
    />

    <BaseSelect
      v-model="form.rewardingIn"
      name="rewarding"
      :options="rewardKinds"
      :label="t('labels.filters.missions.rewarding')"
      :no-label="true"
      multiple
    />

    <ModelPickerSelect
      v-model="shipValue"
      name="ship"
      :label="t('labels.filters.missions.ship')"
      :query="flightReady"
    />

    <BaseSelect
      v-model="form.locationKindIn"
      name="locationKind"
      :options="locationKinds"
      :label="t('labels.filters.missions.location')"
      :no-label="true"
      multiple
    />

    <BaseSelect
      v-model="form.alignmentIn"
      name="alignment"
      :options="alignments"
      :label="t('labels.filters.missions.alignment')"
      :no-label="true"
      multiple
    />

    <BaseSelect
      v-model="form.kindIn"
      name="kind"
      :options="kinds"
      :label="t('labels.filters.missions.kind')"
      :no-label="true"
      multiple
    />

    <BaseSelect
      v-model="releasedValue"
      name="released"
      :options="releasedOptions"
      :label="t('labels.filters.missions.releasedFilter')"
      :no-label="true"
    />

    <br />
    <Btn :disabled="!isFilterSelected" :block="true" @click="resetFilter">
      <i class="fa-light fa-times" />
      {{ t("actions.resetFilter") }}
    </Btn>
  </form>
</template>
