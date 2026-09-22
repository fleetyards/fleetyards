<script lang="ts">
export default {
  name: "AdminMissionsFilterForm",
};
</script>

<script lang="ts" setup>
import BaseSelect from "@/shared/components/base/Select/index.vue";
import FormInput from "@/shared/components/base/FormInput/index.vue";
import Btn from "@/shared/components/base/Btn/index.vue";
import { InputSizesEnum } from "@/shared/components/base/FormInput/types";
import { useI18n } from "@/shared/composables/useI18n";
import { useMissionFilters } from "@/admin/composables/useMissionFilters";
import {
  type GameMissionQuery,
  useGameMissionOrgs,
  useGameMissionRewardKinds,
} from "@/services/fyAdminApi";

const { t } = useI18n();

const prefillFormValues = (): GameMissionQuery => ({
  nameCont: filters.value.nameCont,
  debugNameCont: filters.value.debugNameCont,
  orgNameEq: filters.value.orgNameEq,
  rewarding: filters.value.rewarding,
  released: filters.value.released,
  named: filters.value.named,
  currentVersion: filters.value.currentVersion,
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

const { data: orgs } = useGameMissionOrgs();
const { data: rewardKinds } = useGameMissionRewardKinds();

// Kept as the string each option carries, never cast to a boolean here.
// `useFilters` drops every falsy value before it builds the route, so a
// `false` would be deleted on its way out and the question would come back as
// the whole catalogue. "false" is truthy and survives, and the API casts it.
const tristate = (key: "released" | "named" | "currentVersion") =>
  computed({
    get: () => {
      const value = form.value[key];
      if (value === undefined || value === null) return undefined;

      return String(value);
    },
    set: (value?: string) => {
      form.value = {
        ...form.value,
        [key]: value as unknown as boolean | undefined,
      };
    },
  });

const releasedValue = tristate("released");
const namedValue = tristate("named");
const currentVersionValue = tristate("currentVersion");

const yesNo = (yes: string, no: string) =>
  computed(() => [
    { value: "true", label: t(yes) },
    { value: "false", label: t(no) },
  ]);

const releasedOptions = yesNo(
  "labels.filters.missions.released",
  "labels.filters.missions.unreleased",
);

// The 74 contracts the game never named. The public catalogue leaves them out
// entirely; here they are the point -- "what did this load bring in that
// nobody can read" is a question only this section asks.
const namedOptions = yesNo(
  "labels.admin.missions.filters.named",
  "labels.admin.missions.filters.unnamed",
);

const currentVersionOptions = yesNo(
  "labels.admin.missions.filters.currentBuild",
  "labels.admin.missions.filters.anyBuild",
);
</script>

<template>
  <form @submit.prevent="filter(form)">
    <Teleport to="#header-left">
      <FormInput
        v-model="form.nameCont"
        :size="InputSizesEnum.MEDIUM"
        name="search"
        translation-key="filters.missions.name"
        :no-label="true"
        :clearable="true"
      />
    </Teleport>

    <!-- A developer's note rather than a name, and searchable for exactly that
         reason: it is how a row is found again in the export when its title is
         a run-time template or absent. -->
    <FormInput
      v-model="form.debugNameCont"
      name="debugName"
      :label="t('labels.admin.missions.filters.debugName')"
      :clearable="true"
    />

    <BaseSelect
      v-model="form.orgNameEq"
      name="org"
      :options="orgs ?? []"
      :label="t('labels.filters.missions.org')"
      :no-label="true"
    />

    <BaseSelect
      v-model="form.rewarding"
      name="rewarding"
      :options="rewardKinds ?? []"
      :label="t('labels.filters.missions.rewarding')"
      :no-label="true"
    />

    <BaseSelect
      v-model="releasedValue"
      name="released"
      :options="releasedOptions"
      :label="t('labels.filters.missions.releasedFilter')"
      :no-label="true"
    />

    <BaseSelect
      v-model="namedValue"
      name="named"
      :options="namedOptions"
      :label="t('labels.admin.missions.filters.namedFilter')"
      :no-label="true"
    />

    <BaseSelect
      v-model="currentVersionValue"
      name="currentVersion"
      :options="currentVersionOptions"
      :label="t('labels.admin.missions.filters.build')"
      :no-label="true"
    />

    <br />
    <Btn :disabled="!isFilterSelected" :block="true" @click="resetFilter">
      <i class="fa-light fa-times" />
      {{ t("actions.resetFilter") }}
    </Btn>
  </form>
</template>
