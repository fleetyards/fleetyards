<script lang="ts">
export default {
  name: "SquadronRankModal",
};
</script>

<script lang="ts" setup>
import { useForm } from "vee-validate";
import { useQueryClient } from "@tanstack/vue-query";
import Modal from "@/shared/components/AppModal/Inner/index.vue";
import FormInput from "@/shared/components/base/FormInput/index.vue";
import FormToggle from "@/shared/components/base/FormToggle/index.vue";
import Btn from "@/shared/components/base/Btn/index.vue";
import { BtnSizesEnum } from "@/shared/components/base/Btn/types";
import { validationErrorFrom } from "@/shared/utils/ApiErrors";
import { useI18n } from "@/shared/composables/useI18n";
import { useAppNotifications } from "@/shared/composables/useAppNotifications";
import { useComlink } from "@/shared/composables/useComlink";
import {
  type FleetSquadronRole,
  type FleetSquadronRoleUpdateInput,
  getFleetSquadronRolesQueryKey,
  useUpdateFleetSquadronRole,
} from "@/services/fyApi";

type Props = {
  fleetSlug: string;
  rank: FleetSquadronRole;
};

const props = defineProps<Props>();

const { t } = useI18n();
const { displaySuccess, displayAlert } = useAppNotifications();
const comlink = useComlink();
const queryClient = useQueryClient();
const submitting = ref(false);

const { defineField, handleSubmit, setErrors } =
  useForm<FleetSquadronRoleUpdateInput>({
    initialValues: {
      name: props.rank.name,
      defaultRank: props.rank.defaultRank || undefined,
    },
  });

const [name, nameProps] = defineField("name");
const [defaultRank, defaultRankProps] = defineField("defaultRank");

// The default only ever moves to a rank, never off one: new members always
// need a rank to start on, and the leadership ranks hold one person each.
const defaultRankEditable = computed(
  () => !props.rank.permanent && !props.rank.defaultRank,
);

const payload = (values: FleetSquadronRoleUpdateInput) => ({
  name: values.name,
  ...(defaultRankEditable.value && values.defaultRank
    ? { defaultRank: true as const }
    : {}),
});
const mutation = useUpdateFleetSquadronRole();

const onSubmit = handleSubmit(async (values) => {
  submitting.value = true;

  try {
    await mutation.mutateAsync({
      fleetSlug: props.fleetSlug,
      id: props.rank.id,
      data: payload(values),
    });
    await queryClient.invalidateQueries({
      queryKey: getFleetSquadronRolesQueryKey(props.fleetSlug),
    });
    displaySuccess({
      text: t("messages.fleet.squadrons.ranks.update.success"),
    });
    comlink.emit("close-modal");
  } catch (error) {
    const { message, formErrors } = validationErrorFrom(error);
    setErrors(formErrors);
    displayAlert({
      text: message || t("messages.fleet.squadrons.ranks.update.failure"),
    });
  } finally {
    submitting.value = false;
  }
});
</script>

<template>
  <Modal :title="t('headlines.fleets.squadrons.editRank')">
    <form id="squadron-rank-form" @submit.prevent="onSubmit">
      <FormInput
        v-model="name"
        v-bind="nameProps"
        name="name"
        :label="t('labels.fleet.squadrons.rankName')"
        rules="required"
        autofocus
        data-test="squadron-rank-name"
      />
      <FormToggle
        v-if="!rank.permanent"
        v-model="defaultRank"
        v-bind="defaultRankProps"
        name="defaultRank"
        :label="t('labels.fleet.squadrons.defaultRankToggle')"
        :disabled="!defaultRankEditable"
        data-test="squadron-rank-default"
      />
    </form>
    <template #footer>
      <Btn :loading="submitting" :size="BtnSizesEnum.LG" @click="onSubmit">
        {{ t("actions.save") }}
      </Btn>
    </template>
  </Modal>
</template>
