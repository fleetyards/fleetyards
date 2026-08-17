<script lang="ts">
export default {
  name: "AdminFleetMemberEditPage",
};
</script>

<script lang="ts" setup>
import { useI18n } from "@/shared/composables/useI18n";
import Heading from "@/shared/components/base/Heading/index.vue";
import AsyncData from "@/shared/components/AsyncData.vue";
import FilterGroup from "@/shared/components/base/FilterGroup/index.vue";
import FormActions from "@/shared/components/base/FormActions/index.vue";
import { useForm } from "vee-validate";
import { useQueryClient } from "@tanstack/vue-query";
import {
  type Fleet,
  type FilterOption,
  useFleetMember as useFleetMemberQuery,
  useUpdateFleetMember,
  getFleetMembersQueryKey,
  getFleetMemberQueryKey,
} from "@/services/fyAdminApi";
import { useAppNotifications } from "@/shared/composables/useAppNotifications";

type Props = {
  fleet: Fleet;
};

const props = defineProps<Props>();

const { t } = useI18n();
const router = useRouter();
const route = useRoute();
const queryClient = useQueryClient();
const { displayAlert } = useAppNotifications();

const memberId = computed(() => route.params.memberId as string);

const { data: member, ...asyncStatus } = useFleetMemberQuery(
  props.fleet.id,
  memberId,
);

const roleOptions = computed<FilterOption[]>(() =>
  (props.fleet.fleetRoles || []).map((role) => ({
    value: role.id,
    label: role.name,
  })),
);

const { defineField, handleSubmit, resetForm, meta } = useForm<{
  fleetRoleId: string;
}>({
  initialValues: { fleetRoleId: "" },
  validationSchema: { fleetRoleId: "required" },
});

const [fleetRoleId, fleetRoleIdProps] = defineField("fleetRoleId");

watch(
  member,
  (value) => {
    if (value?.roleId) {
      resetForm({ values: { fleetRoleId: value.roleId } });
    }
  },
  { immediate: true },
);

const submitting = ref(false);

const updateMutation = useUpdateFleetMember({
  mutation: {
    onSettled: () => {
      void Promise.all([
        queryClient.invalidateQueries({
          queryKey: getFleetMembersQueryKey(props.fleet.id),
        }),
        queryClient.invalidateQueries({
          queryKey: getFleetMemberQueryKey(props.fleet.id, memberId.value),
        }),
      ]);
    },
  },
});

const backToMembers = () =>
  router.push({
    name: "admin-fleet-members",
    params: { id: props.fleet.id },
  });

const onSubmit = handleSubmit(async (values) => {
  submitting.value = true;

  await updateMutation
    .mutateAsync({
      fleetId: props.fleet.id,
      id: memberId.value,
      data: { fleetRoleId: values.fleetRoleId },
    })
    .then(async () => {
      await backToMembers();
    })
    .catch((error) => {
      displayAlert({ text: error.response?.data?.message });
    })
    .finally(() => {
      submitting.value = false;
    });
});

const handleCancel = async () => {
  await backToMembers();
};
</script>

<template>
  <Heading hero>{{ t("headlines.admin.fleets.memberEdit") }}</Heading>
  <AsyncData :async-status="asyncStatus">
    <template #resolved>
      <form id="admin-fleet-member-edit-form" @submit.prevent="onSubmit">
        <FilterGroup
          v-model="fleetRoleId"
          v-bind="fleetRoleIdProps"
          name="fleetRoleId"
          :options="roleOptions"
          :label="t('labels.fleet.members.role')"
          :searchable="false"
          :nullable="false"
        />
        <FormActions
          :submitting="submitting"
          form-id="admin-fleet-member-edit-form"
          :dirty="meta.dirty || meta.touched"
          @cancel="handleCancel"
        />
      </form>
    </template>
  </AsyncData>
</template>
