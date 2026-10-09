<script lang="ts">
export default {
  name: "FleetRoleModal",
};
</script>

<script lang="ts" setup>
import { useForm } from "vee-validate";
import { useQueryClient } from "@tanstack/vue-query";
import Modal from "@/shared/components/AppModal/Inner/index.vue";
import FormInput from "@/shared/components/base/FormInput/index.vue";
import FormToggle from "@/shared/components/base/FormToggle/index.vue";
import Btn from "@/shared/components/base/Btn/index.vue";
import { BtnTypesEnum } from "@/shared/components/base/Btn/types";
import { validationErrorFrom } from "@/shared/utils/ApiErrors";
import { useI18n } from "@/shared/composables/useI18n";
import { useAppNotifications } from "@/shared/composables/useAppNotifications";
import { useComlink } from "@/shared/composables/useComlink";
import {
  type FleetRoleExtended,
  type FleetRoleUpdateInput,
  getFleetMembershipQueryKey,
  getFleetMembersQueryKey,
  getFleetRolesQueryKey,
  useUpdateFleetRole,
} from "@/services/fyApi";

interface Props {
  fleetSlug: string;
  role: FleetRoleExtended;
}

const props = defineProps<Props>();

const { t } = useI18n();
const { displaySuccess, displayAlert } = useAppNotifications();
const comlink = useComlink();
const queryClient = useQueryClient();
const submitting = ref(false);

const { defineField, handleSubmit, setErrors } = useForm<FleetRoleUpdateInput>({
  initialValues: { name: props.role.name },
});

const [name, nameProps] = defineField("name");
const mutation = useUpdateFleetRole();

const onSubmit = handleSubmit(async (values) => {
  submitting.value = true;

  try {
    await mutation.mutateAsync({
      fleetSlug: props.fleetSlug,
      id: props.role.id,
      // The name alone: the toggle below registers with the form too, and
      // the endpoint takes nothing else.
      data: { name: values.name },
    });
    // Every list that names the role, not just the roles page.
    await Promise.all(
      [
        getFleetRolesQueryKey(props.fleetSlug),
        getFleetMembersQueryKey(props.fleetSlug),
        getFleetMembershipQueryKey(props.fleetSlug),
      ].map((queryKey) => queryClient.invalidateQueries({ queryKey })),
    );
    displaySuccess({ text: t("messages.fleet.roles.update.success") });
    comlink.emit("close-modal");
  } catch (error) {
    const { message, formErrors } = validationErrorFrom(error);
    setErrors(formErrors);
    displayAlert({
      text: message || t("messages.fleet.roles.update.failure"),
    });
  } finally {
    submitting.value = false;
  }
});
</script>

<template>
  <Modal :title="t('headlines.fleets.editRole')">
    <form id="fleet-role-form" @submit.prevent="onSubmit">
      <FormInput
        v-model="name"
        v-bind="nameProps"
        name="name"
        :label="t('labels.fleet.roles.name')"
        rules="required"
        autofocus
        data-test="fleet-role-name"
      />
      <!-- Shown, not offered: a fleet has no other role to move the default
           to until it can add its own. -->
      <FormToggle
        v-if="!role.permanent"
        :model-value="role.defaultRole"
        name="defaultRole"
        :label="t('labels.fleet.roles.defaultToggle')"
        disabled
        data-test="fleet-role-default"
      />
    </form>
    <template #footer>
      <Btn
        :type="BtnTypesEnum.SUBMIT"
        form="fleet-role-form"
        :loading="submitting"
      >
        {{ t("actions.save") }}
      </Btn>
    </template>
  </Modal>
</template>
