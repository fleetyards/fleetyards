<script lang="ts">
export default {
  name: "FleetMembershipPage",
};
</script>

<script lang="ts" setup>
import { useI18n } from "@/shared/composables/useI18n";
import { useForm } from "vee-validate";
import Btn from "@/shared/components/base/Btn/index.vue";
import FormCheckbox from "@/shared/components/base/FormCheckbox/index.vue";
import FilterGroup from "@/shared/components/base/FilterGroup/index.vue";
import type { FilterOption } from "@/services/fyApi";
import {
  type Fleet,
  type FleetMember,
  type FleetMembershipUpdateInput,
  FleetMembershipShipsFilterEnum,
} from "@/services/fyApi";
import { useAppNotifications } from "@/shared/composables/useAppNotifications";
import { useUpdateFleetMembership } from "@/services/fyApi/services/fleet-membership/fleet-membership";
import { useHangarGroups } from "@/services/fyApi/services/hangar-groups/hangar-groups";

type Props = {
  fleet: Fleet;
  membership: FleetMember;
};

const props = defineProps<Props>();

const { t } = useI18n();
const { displaySuccess, displayAlert } = useAppNotifications();

const submitting = ref(false);

const initialValues = ref<FleetMembershipUpdateInput>({
  primary: props.membership.primary,
  shipsFilter: props.membership.shipsFilter,
  hangarGroupId: props.membership.hangarGroupId,
});

const { defineField, handleSubmit, setErrors } = useForm({
  initialValues: initialValues.value,
});

const [primary, primaryProps] = defineField("primary");
const [shipsFilter, shipsFilterProps] = defineField("shipsFilter");
const [hangarGroupId, hangarGroupIdProps] = defineField("hangarGroupId");

// get fleet() {
//   return fleetsCollection.record;
// }

// get metaTitle() {
//   if (!this.fleet) {
//     return null;
//   }

//   return this.$t("title.fleets.settings", { fleet: this.fleet.name });
// }

// get crumbs() {
//   if (!this.fleet) {
//     return [];
//   }

//   return [
//     {
//       to: {
//         name: "fleet",
//         params: {
//           slug: this.fleet.slug,
//         },
//       },

//       label: this.fleet.name,
//     },
//   ];
// }

const shipsFilterIsHangarGroup = computed(() => {
  return shipsFilter.value === FleetMembershipShipsFilterEnum.hangar_group;
});

const shipsFilterOptions = computed<FilterOption[]>(() => [
  {
    label: t("labels.fleet.members.shipsFilter.values.all"),
    value: FleetMembershipShipsFilterEnum.all,
  },
  {
    label: t("labels.fleet.members.shipsFilter.values.hangar_group"),
    value: FleetMembershipShipsFilterEnum.hangar_group,
  },
  {
    label: t("labels.fleet.members.shipsFilter.values.hide"),
    value: FleetMembershipShipsFilterEnum.hide,
  },
]);

// Fetch hangar groups
const { data: hangarGroups } = useHangarGroups();

const hangarGroupOptions = computed<FilterOption[]>(() => {
  if (!hangarGroups.value) return [];

  return hangarGroups.value.map((group) => ({
    label: group.name,
    value: group.id,
  }));
});

// Clear hangar group selection when ships filter changes
watch(shipsFilterIsHangarGroup, (newValue) => {
  if (!newValue) {
    hangarGroupId.value = null;
  }
});

const { mutateAsync: updateMembership } = useUpdateFleetMembership();

const onSubmit = handleSubmit(async (values) => {
  submitting.value = true;

  try {
    await updateMembership({
      fleetSlug: props.fleet.slug,
      data: values,
    });

    displaySuccess({
      text: t("messages.fleet.members.update.success"),
    });

    // TODO: Emit fleet-update event when event system is implemented
  } catch (error) {
    const errorResponse = error as {
      response?: {
        data?: { errors?: Record<string, string[]>; message?: string };
      };
    };

    if (errorResponse.response?.data?.errors) {
      setErrors(errorResponse.response.data.errors);
    }

    displayAlert({
      text:
        errorResponse.response?.data?.message ||
        t("messages.fleet.members.update.failure"),
    });
  } finally {
    submitting.value = false;
  }
});
</script>

<template>
  <form @submit.prevent="onSubmit">
    <div class="row">
      <div class="col-12 col-md-6">
        <FormCheckbox
          v-model="primary"
          name="primary"
          translation-key="fleet.members.primary"
          v-bind="primaryProps"
        />
      </div>
    </div>
    <br />
    <div class="row">
      <div class="col-12 col-md-6">
        <FilterGroup
          v-model="shipsFilter"
          name="shipsFilter"
          translation-key="fleet.members.shipsFilter"
          :options="shipsFilterOptions"
          v-bind="shipsFilterProps"
        />
      </div>
      <div v-if="shipsFilterIsHangarGroup" class="col-12 col-md-6">
        <FilterGroup
          v-model="hangarGroupId"
          name="hangarGroupId"
          translation-key="fleet.members.hangarGroupId"
          :options="hangarGroupOptions"
          v-bind="hangarGroupIdProps"
        />
      </div>
    </div>
    <hr />
    <Btn
      :loading="submitting"
      type="submit"
      size="large"
      data-test="fleet-membership-save"
    >
      {{ t("actions.save") }}
    </Btn>
  </form>
</template>
