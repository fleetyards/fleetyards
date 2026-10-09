<script lang="ts">
export default {
  name: "SquadronMemberEditModal",
};
</script>

<script lang="ts" setup>
import { useForm } from "vee-validate";
import Modal from "@/shared/components/AppModal/Inner/index.vue";
import FormDatePicker from "@/shared/components/base/FormDatePicker/index.vue";
import BaseSelect from "@/shared/components/base/Select/index.vue";
import Btn from "@/shared/components/base/Btn/index.vue";
import { BtnTypesEnum } from "@/shared/components/base/Btn/types";
import { validationErrorFrom } from "@/shared/utils/ApiErrors";
import { useI18n } from "@/shared/composables/useI18n";
import { useAppNotifications } from "@/shared/composables/useAppNotifications";
import { useComlink } from "@/shared/composables/useComlink";
import {
  type FleetSquadronMemberUpdateInput,
  type FleetSquadronRole,
  useUpdateFleetSquadronMember,
} from "@/services/fyApi";

type Props = {
  fleetSlug: string;
  squadronSlug: string;
  username: string;
  membershipCreatedAt?: string;
  roleId?: string;
  // The ranks the editor may move this member between, the current one
  // included. Empty when the rank is not theirs to change.
  rankOptions?: FleetSquadronRole[];
  dateEditable?: boolean;
};

const props = withDefaults(defineProps<Props>(), {
  membershipCreatedAt: undefined,
  roleId: undefined,
  rankOptions: () => [],
  dateEditable: true,
});

const { t } = useI18n();
const { displaySuccess, displayAlert } = useAppNotifications();
const comlink = useComlink();
const submitting = ref(false);

const rankEditable = computed(() => props.rankOptions.length > 1);

const rankSelectOptions = computed(() =>
  props.rankOptions.map((rank) => ({ label: rank.name, value: rank.id })),
);

const initialCreatedAt = props.membershipCreatedAt?.slice(0, 10);

const { defineField, handleSubmit, setErrors } =
  useForm<FleetSquadronMemberUpdateInput>({
    initialValues: {
      createdAt: initialCreatedAt,
      fleetSquadronRoleId: props.roleId,
    },
  });

const [createdAt, createdAtProps] = defineField("createdAt");
const [fleetSquadronRoleId, fleetSquadronRoleIdProps] = defineField(
  "fleetSquadronRoleId",
);
const mutation = useUpdateFleetSquadronMember();

// Only what the editor changed and may change: the update is refused as a
// whole when it carries a field the editor has no right to, and the date is a
// day while the stored join is a moment -- resending it unchanged would drop
// the time of day.
const payload = (values: FleetSquadronMemberUpdateInput) => {
  const data: FleetSquadronMemberUpdateInput = {};
  if (
    props.dateEditable &&
    values.createdAt &&
    values.createdAt !== initialCreatedAt
  ) {
    data.createdAt = values.createdAt;
  }
  if (rankEditable.value && values.fleetSquadronRoleId !== props.roleId) {
    data.fleetSquadronRoleId = values.fleetSquadronRoleId;
  }
  return data;
};

const onSubmit = handleSubmit(async (values) => {
  submitting.value = true;

  try {
    await mutation.mutateAsync({
      fleetSlug: props.fleetSlug,
      fleetSquadronSlug: props.squadronSlug,
      username: props.username,
      data: payload(values),
    });
    displaySuccess({ text: t("messages.fleet.squadrons.update.success") });
    comlink.emit("fleet-squadron-members-updated");
    comlink.emit("close-modal");
  } catch (error) {
    const { message, formErrors } = validationErrorFrom(error);
    setErrors(formErrors);
    displayAlert({
      text: message || t("messages.fleet.squadrons.update.failure"),
    });
  } finally {
    submitting.value = false;
  }
});
</script>

<template>
  <Modal :title="t('headlines.fleets.squadrons.editMember')">
    <form id="squadron-member-edit-form" @submit.prevent="onSubmit">
      <BaseSelect
        v-if="rankEditable"
        v-model="fleetSquadronRoleId"
        v-bind="fleetSquadronRoleIdProps"
        name="fleetSquadronRoleId"
        :options="rankSelectOptions"
        :label="t('labels.fleet.squadrons.rank')"
        :searchable="false"
        unsorted
        data-test="squadron-member-rank"
      />
      <FormDatePicker
        v-if="dateEditable"
        v-model="createdAt"
        v-bind="createdAtProps"
        name="createdAt"
        :label="t('labels.fleet.squadrons.joinedAt')"
      />
    </form>
    <template #footer>
      <Btn
        :type="BtnTypesEnum.SUBMIT"
        form="squadron-member-edit-form"
        :loading="submitting"
      >
        {{ t("actions.save") }}
      </Btn>
    </template>
  </Modal>
</template>
