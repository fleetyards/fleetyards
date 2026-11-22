<script lang="ts">
export default {
  name: "SquadronRoleFilterModal",
};
</script>

<script lang="ts" setup>
import Modal from "@/shared/components/AppModal/Inner/index.vue";
import Btn from "@/shared/components/base/Btn/index.vue";
import { BtnTypesEnum } from "@/shared/components/base/Btn/types";
import ClassificationSelect from "@/frontend/components/base/ModelClassificationSelect/index.vue";
import FocusSelect from "@/frontend/components/base/ModelFocusSelect/index.vue";
import { validationErrorFrom } from "@/shared/utils/ApiErrors";
import { useI18n } from "@/shared/composables/useI18n";
import { useAppNotifications } from "@/shared/composables/useAppNotifications";
import { useComlink } from "@/shared/composables/useComlink";
import { useModalDirty } from "@/shared/components/AppModal/dirty";
import {
  type FleetSquadron,
  type ModelFocusEnum,
  useUpdateFleetSquadron,
} from "@/services/fyApi";

type Props = {
  fleetSlug: string;
  squadron: FleetSquadron;
};

const props = defineProps<Props>();

const { t } = useI18n();
const { displaySuccess, displayAlert } = useAppNotifications();
const comlink = useComlink();
const submitting = ref(false);

// Plain refs rather than form fields: the selects replace their whole value on
// every pick, and a form's copy of the array leaves the picked rows unmarked.
const initial = {
  classifications: [...props.squadron.classifications],
  foci: [...props.squadron.foci],
};
const classifications = ref<string[]>([...initial.classifications]);
const foci = ref<string[]>([...initial.foci]);

const toList = (value: string | string[] | undefined) =>
  (Array.isArray(value) ? value : value ? [value] : []).filter(Boolean);

useModalDirty(
  computed(
    () =>
      JSON.stringify([toList(classifications.value), toList(foci.value)]) !==
      JSON.stringify([initial.classifications, initial.foci]),
  ),
);

const mutation = useUpdateFleetSquadron();

const onSubmit = async () => {
  submitting.value = true;

  try {
    await mutation.mutateAsync({
      fleetSlug: props.fleetSlug,
      slug: props.squadron.slug,
      data: {
        classifications: toList(classifications.value),
        foci: toList(foci.value) as ModelFocusEnum[],
      },
    });
    displaySuccess({ text: t("messages.fleet.squadrons.update.success") });
    comlink.emit("fleet-squadron-updated");
    comlink.emit("close-modal", true);
  } catch (error) {
    const { message } = validationErrorFrom(error);
    displayAlert({
      text: message || t("messages.fleet.squadrons.update.failure"),
    });
  } finally {
    submitting.value = false;
  }
};
</script>

<template>
  <Modal :title="t('headlines.fleets.squadrons.editRoleFilter')">
    <form id="squadron-role-filter-form" @submit.prevent="onSubmit">
      <p class="squadron-role-filter-modal__hint">
        {{ t("labels.fleet.squadrons.roleFilterHint") }}
      </p>
      <ClassificationSelect
        v-model="classifications"
        name="classifications"
        :no-label="false"
        data-test="squadron-role-filter-classifications"
      />
      <FocusSelect
        v-model="foci"
        name="foci"
        :no-label="false"
        data-test="squadron-role-filter-foci"
      />
    </form>
    <template #footer>
      <Btn
        :type="BtnTypesEnum.SUBMIT"
        form="squadron-role-filter-form"
        :loading="submitting"
        data-test="squadron-role-filter-save"
      >
        {{ t("actions.save") }}
      </Btn>
    </template>
  </Modal>
</template>

<style lang="scss" scoped>
.squadron-role-filter-modal__hint {
  margin: 0 0 16px;
  color: var(--color-text-dim);
}
</style>
