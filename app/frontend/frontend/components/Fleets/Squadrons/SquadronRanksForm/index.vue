<script lang="ts">
export default {
  name: "SquadronRanksForm",
};
</script>

<script lang="ts" setup>
import { useForm } from "vee-validate";
import FormInput from "@/shared/components/base/FormInput/index.vue";
import FormActions from "@/shared/components/base/FormActions/index.vue";
import { useI18n } from "@/shared/composables/useI18n";
import { useAppNotifications } from "@/shared/composables/useAppNotifications";
import { validationErrorFrom } from "@/shared/utils/ApiErrors";
import {
  type FleetSquadronRole,
  FleetSquadronRoleKeyEnum,
  getFleetSquadronRolesQueryKey,
  useUpdateFleetSquadronRole,
} from "@/services/fyApi";
import { useQueryClient } from "@tanstack/vue-query";

type Props = {
  fleetSlug: string;
  ranks: FleetSquadronRole[];
};

const props = defineProps<Props>();

const { t } = useI18n();
const { displaySuccess, displayAlert } = useAppNotifications();
const queryClient = useQueryClient();
const submitting = ref(false);

const initialValues = computed(() =>
  Object.fromEntries(props.ranks.map((rank) => [rank.key, rank.name])),
);

const { defineField, handleSubmit, meta, resetForm } = useForm<
  Record<string, string>
>({
  initialValues: initialValues.value,
});

const fields = Object.fromEntries(
  Object.values(FleetSquadronRoleKeyEnum).map((key) => [key, defineField(key)]),
);

const mutation = useUpdateFleetSquadronRole();

// One request per renamed rank: the four are separate rows, and a name left
// alone is not written again.
const onSubmit = handleSubmit(async (values) => {
  submitting.value = true;

  const renamed = props.ranks.filter((rank) => values[rank.key] !== rank.name);

  try {
    await Promise.all(
      renamed.map((rank) =>
        mutation.mutateAsync({
          fleetSlug: props.fleetSlug,
          id: rank.id,
          data: { name: values[rank.key] },
        }),
      ),
    );
    await queryClient.invalidateQueries({
      queryKey: getFleetSquadronRolesQueryKey(props.fleetSlug),
    });
    resetForm({ values });
    displaySuccess({
      text: t("messages.fleet.squadrons.ranks.update.success"),
    });
  } catch (error) {
    const { message } = validationErrorFrom(error);
    displayAlert({
      text: message || t("messages.fleet.squadrons.ranks.update.failure"),
    });
  } finally {
    submitting.value = false;
  }
});
</script>

<template>
  <form id="squadron-ranks-form" @submit.prevent="onSubmit">
    <p class="squadron-ranks-form__hint">
      {{ t("labels.fleet.squadrons.ranksHint") }}
    </p>
    <div class="row">
      <div v-for="rank in ranks" :key="rank.id" class="col-12 col-md-6">
        <FormInput
          v-model="fields[rank.key][0].value"
          v-bind="fields[rank.key][1].value"
          :name="rank.key"
          :label="rank.name"
          :info="t(`labels.fleet.squadrons.rankSlots.${rank.key}`)"
          rules="required"
          :data-test="`squadron-rank-name-${rank.key}`"
        />
      </div>
    </div>
    <FormActions
      :submitting="submitting"
      form-id="squadron-ranks-form"
      :dirty="meta.dirty"
      @cancel="resetForm()"
    />
  </form>
</template>

<style lang="scss" scoped>
.squadron-ranks-form__hint {
  color: var(--color-text-dim);
}
</style>
