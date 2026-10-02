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
    initialValues: { name: props.rank.name },
  });

const [name, nameProps] = defineField("name");
const mutation = useUpdateFleetSquadronRole();

const onSubmit = handleSubmit(async (values) => {
  submitting.value = true;

  try {
    await mutation.mutateAsync({
      fleetSlug: props.fleetSlug,
      id: props.rank.id,
      data: values,
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
    </form>
    <template #footer>
      <div class="float-sm-right">
        <Btn :loading="submitting" :size="BtnSizesEnum.LG" @click="onSubmit">
          {{ t("actions.save") }}
        </Btn>
      </div>
    </template>
  </Modal>
</template>
