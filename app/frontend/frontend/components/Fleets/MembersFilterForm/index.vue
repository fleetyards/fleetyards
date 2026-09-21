<script lang="ts">
export default {
  name: "FleetMembersFilterForm",
};
</script>

<script lang="ts" setup>
import BaseSelect from "@/shared/components/base/Select/index.vue";
import FormInput from "@/shared/components/base/FormInput/index.vue";
import Btn from "@/shared/components/base/Btn/index.vue";
import {
  FleetMemberQuery,
  type FilterOption,
  useFleetSquadrons,
} from "@/services/fyApi";
import { useI18n } from "@/shared/composables/useI18n";
import { useFilters } from "@/shared/composables/useFilters";
import {
  MEMBERS_VIEW_FILTER_KEYS,
  type MembersView,
} from "@/frontend/composables/useMembersView";
import {
  InputSizesEnum,
  InputTypesEnum,
} from "@/shared/components/base/FormInput/types";

type Props = {
  variant?: MembersView;
  fleetSlug?: string;
};

const props = withDefaults(defineProps<Props>(), {
  variant: "members",
  fleetSlug: undefined,
});

const { t } = useI18n();

const { filter, resetFilter, isFilterSelected, filters } =
  useFilters<FleetMemberQuery>({
    updateCallback: setupForm,
  });

// Only the fields this variant asks about, read from the same map the page
// clears the other variant's by, so a field added here cannot be forgotten
// there and go on filtering the list that never shows it.
const variantFilters = () =>
  Object.fromEntries(
    MEMBERS_VIEW_FILTER_KEYS[props.variant].map((key) => [
      key,
      // A multi-select binds to an array; unset, that has to be an empty one.
      key === "stateIn" ? filters.value.stateIn || [] : filters.value[key],
    ]),
  ) as FleetMemberQuery;

function setupForm() {
  form.value = {
    usernameCont: filters.value.usernameCont,
    roleIn: filters.value.roleIn || [],
    squadronSlugIn: filters.value.squadronSlugIn || [],
    sorts: filters.value.sorts,
    ...variantFilters(),
  };
}

const form = ref<FleetMemberQuery>({});

/*
 * The view is not a filter, so it is kept out of `filters` -- which means a
 * bare switch between the roster and the invites changes nothing this form
 * watches. Without this the form keeps the fields it was holding for the list
 * it has just left, and writes them back into the URL on the next keystroke.
 */
watch(() => props.variant, setupForm);

watch(
  () => form.value,
  () => {
    filter(form.value);
  },
  { deep: true },
);

const roleOptions: FilterOption[] = [
  {
    label: t("labels.fleet.members.roles.admin"),
    value: "admin",
  },
  {
    label: t("labels.fleet.members.roles.officer"),
    value: "officer",
  },
  {
    label: t("labels.fleet.members.roles.member"),
    value: "member",
  },
];

/*
 * Only asked for once the page says which fleet this is. The form is mounted
 * from the members page, which has the fleet; a caller that does not pass it
 * gets the rest of the form and no squadron filter, rather than a request for
 * `/fleets/undefined/squadrons`.
 */
const { data: squadrons } = useFleetSquadrons(
  computed(() => props.fleetSlug ?? ""),
  {},
  { query: { enabled: computed(() => !!props.fleetSlug) } },
);

const squadronOptions = computed<FilterOption[]>(() =>
  (squadrons.value?.items ?? []).map((squadron) => ({
    label: squadron.name,
    value: squadron.slug,
  })),
);

const stateOptions: FilterOption[] = [
  {
    label: t("labels.fleet.members.invited"),
    value: "invited",
  },
  {
    label: t("labels.fleet.members.requested"),
    value: "requested",
  },
  {
    label: t("labels.fleet.members.declined"),
    value: "declined",
  },
];
</script>

<template>
  <form @submit.prevent="filter(form)">
    <!-- In the page header rather than this sidebar, like the hangar's: a
         members list is searched by name far more often than it is filtered, and
         the sidebar is collapsed by default. -->
    <Teleport to="#header-left">
      <FormInput
        id="username"
        name="username"
        :size="InputSizesEnum.MEDIUM"
        v-model="form.usernameCont"
        translation-key="filters.fleets.members.username"
        :no-label="true"
        :clearable="true"
      />
    </Teleport>

    <BaseSelect
      v-model="form.roleIn"
      :options="roleOptions"
      :label="t('labels.filters.fleets.members.role')"
      name="role"
      :multiple="true"
      :no-label="true"
    />

    <BaseSelect
      v-if="squadronOptions.length"
      v-model="form.squadronSlugIn"
      :options="squadronOptions"
      :label="t('labels.filters.fleets.members.squadron')"
      name="squadron"
      :multiple="true"
      :no-label="true"
    />

    <template v-if="variant === 'members'">
      <div class="row">
        <div class="col-6">
          <FormInput
            v-model="form.acceptedAtGteq"
            name="accepted-at-gteq"
            :type="InputTypesEnum.DATE"
            translation-key="filters.fleets.members.acceptedAtGt"
            :no-placeholder="true"
          />
        </div>
        <div class="col-6">
          <FormInput
            v-model="form.acceptedAtLteq"
            name="accepted-at-lteq"
            :type="InputTypesEnum.DATE"
            translation-key="filters.fleets.members.acceptedAtLt"
            :no-placeholder="true"
          />
        </div>
      </div>
    </template>

    <template v-if="variant === 'invites'">
      <BaseSelect
        v-model="form.stateIn"
        :options="stateOptions"
        :label="t('labels.filters.fleets.members.state')"
        name="state"
        :multiple="true"
        :no-label="true"
      />

      <div class="row">
        <div class="col-6">
          <FormInput
            v-model="form.invitedAtGteq"
            name="invited-at-gteq"
            :type="InputTypesEnum.DATE"
            translation-key="filters.fleets.members.invitedAtGt"
            :no-placeholder="true"
          />
        </div>
        <div class="col-6">
          <FormInput
            v-model="form.invitedAtLteq"
            name="invited-at-lteq"
            :type="InputTypesEnum.DATE"
            translation-key="filters.fleets.members.invitedAtLt"
            :no-placeholder="true"
          />
        </div>
      </div>

      <div class="row">
        <div class="col-6">
          <FormInput
            v-model="form.requestedAtGteq"
            name="requested-at-gteq"
            :type="InputTypesEnum.DATE"
            translation-key="filters.fleets.members.requestedAtGt"
            :no-placeholder="true"
          />
        </div>
        <div class="col-6">
          <FormInput
            v-model="form.requestedAtLteq"
            name="requested-at-lteq"
            :type="InputTypesEnum.DATE"
            translation-key="filters.fleets.members.requestedAtLt"
            :no-placeholder="true"
          />
        </div>
      </div>

      <div class="row">
        <div class="col-6">
          <FormInput
            v-model="form.declinedAtGteq"
            name="declined-at-gteq"
            :type="InputTypesEnum.DATE"
            translation-key="filters.fleets.members.declinedAtGt"
            :no-placeholder="true"
          />
        </div>
        <div class="col-6">
          <FormInput
            v-model="form.declinedAtLteq"
            name="declined-at-lteq"
            :type="InputTypesEnum.DATE"
            translation-key="filters.fleets.members.declinedAtLt"
            :no-placeholder="true"
          />
        </div>
      </div>
    </template>

    <Btn :disabled="!isFilterSelected" :block="true" @click="resetFilter">
      <i class="fa-light fa-times" />
      {{ t("actions.resetFilter") }}
    </Btn>
  </form>
</template>
