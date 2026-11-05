<script lang="ts">
export default {
  name: "HangarPlannerMeltModal",
};
</script>

<script lang="ts" setup>
import Modal from "@/shared/components/AppModal/Inner/index.vue";
import Btn from "@/shared/components/base/Btn/index.vue";
import { BtnTypesEnum } from "@/shared/components/base/Btn/types";
import FormInput from "@/shared/components/base/FormInput/index.vue";
import { InputTypesEnum } from "@/shared/components/base/FormInput/types";
import Pill from "@/shared/components/base/Pill/index.vue";
import { PillVariantsEnum } from "@/shared/components/base/Pill/types";
import MeltContents from "@/frontend/components/Hangar/Planner/MeltContents/index.vue";
import { pledgeUnlisted } from "@/frontend/components/Hangar/Planner/format";
import { useI18n } from "@/shared/composables/useI18n";
import { useAppNotifications } from "@/shared/composables/useAppNotifications";
import { useComlink } from "@/shared/composables/useComlink";
import { useModalDirty } from "@/shared/components/AppModal/dirty";
import { useHangarPlanCache } from "@/frontend/composables/useHangarPlanCache";
import {
  type HangarPlanMelt,
  useCreateHangarPlanMelt,
  useHangarPlanResources,
  useUpdateHangarPlanMelt,
} from "@/services/fyApi";

type Props = {
  planId: string;
  // The melt to edit, or the hangar ship to melt.
  melt?: HangarPlanMelt;
  vehicleId?: string;
};

const props = defineProps<Props>();

const { t } = useI18n();
const { displayAlert } = useAppNotifications();
const comlink = useComlink();
const { updatePlan } = useHangarPlanCache();

const { data: resources } = useHangarPlanResources(() => props.planId);

const submitting = ref(false);
const valueOverride = ref<string>(props.melt?.valueOverride?.toString() ?? "");

const touched = ref(false);
watch(valueOverride, () => {
  touched.value = true;
});
useModalDirty(touched);

const vehicleId = computed(() => props.melt?.vehicleId ?? props.vehicleId);

const vehicle = computed(() =>
  (resources.value?.vehicles ?? []).find(
    (entry) => entry.id === vehicleId.value,
  ),
);

// RSI says per pledge whether it melts, but only for ships the hangar sync
// read; anyone who keeps their hangar by hand can still melt any ship.
const meltBadge = computed(() => {
  if (!vehicle.value) return undefined;
  if (vehicle.value.meltable === false) {
    return t("hangarPlanner.meltList.notMeltable");
  }
  if (vehicle.value.meltable === null || vehicle.value.meltable === undefined) {
    return t("hangarPlanner.meltList.notSynced");
  }
  return undefined;
});

const contents = computed(() => {
  const ship = vehicle.value;
  if (!ship) return undefined;

  const inPackage =
    (ship.pledgeItemCount ?? 0) > 1 ||
    ship.pledgeShips.length > 0 ||
    ship.pledgeItems.length > 0;
  if (!inPackage) return undefined;

  return {
    name: ship.pledgeName,
    ships: ship.pledgeShips,
    items: ship.pledgeItems,
    unlisted: pledgeUnlisted(ship),
  };
});

const placeholder = computed(() => {
  const credit =
    props.melt?.value ??
    vehicle.value?.meltValue ??
    vehicle.value?.model.pledgePrice;
  return typeof credit === "number" ? String(credit) : undefined;
});

const createMutation = useCreateHangarPlanMelt();
const updateMutation = useUpdateHangarPlanMelt();

const onSubmit = async () => {
  submitting.value = true;

  const value = valueOverride.value === "" ? null : Number(valueOverride.value);

  try {
    const plan = props.melt
      ? await updateMutation.mutateAsync({
          hangarPlanId: props.planId,
          id: props.melt.id,
          data: { valueOverride: value },
        })
      : await createMutation.mutateAsync({
          hangarPlanId: props.planId,
          data: { vehicleId: vehicleId.value as string, valueOverride: value },
        });

    updatePlan(plan);
    comlink.emit("close-modal", true);
  } catch {
    displayAlert({ text: t("hangarPlanner.messages.saveFailed") });
  } finally {
    submitting.value = false;
  }
};
</script>

<template>
  <Modal
    :title="melt ? t('hangarPlanner.editMelt') : t('hangarPlanner.addMelt')"
  >
    <form id="hangar-plan-melt-form" @submit.prevent="onSubmit">
      <p v-if="vehicle" class="melt-ship" data-test="hangar-plan-melt-ship">
        <strong>{{ vehicle.name || vehicle.model.name }}</strong>
        <span v-if="vehicle.name" class="melt-muted">
          {{ vehicle.model.name }}
        </span>
        <Pill v-if="meltBadge" :variant="PillVariantsEnum.WARNING">
          {{ meltBadge }}
        </Pill>
      </p>
      <section
        v-if="contents"
        class="melt-contents"
        data-test="hangar-plan-melt-contents"
      >
        <span class="melt-label">{{
          contents.name
            ? t("hangarPlanner.meltList.contentsOf", { name: contents.name })
            : t("hangarPlanner.meltList.contents")
        }}</span>
        <MeltContents
          :ships="contents.ships"
          :items="contents.items"
          :unlisted="contents.unlisted"
        />
      </section>
      <FormInput
        v-model="valueOverride"
        name="valueOverride"
        :type="InputTypesEnum.NUMBER"
        :min="0"
        :step="0.01"
        prefix="$"
        :label="t('hangarPlanner.fields.meltValue')"
        :info="t('hangarPlanner.fields.meltValueInfo')"
        :placeholder="placeholder"
        standalone
      />
    </form>

    <template #footer>
      <Btn
        :type="BtnTypesEnum.SUBMIT"
        form="hangar-plan-melt-form"
        :loading="submitting"
        data-test="hangar-plan-melt-save"
      >
        {{ t("actions.save") }}
      </Btn>
    </template>
  </Modal>
</template>

<style lang="scss" scoped>
.melt-label {
  display: block;
  margin-bottom: 6px;
}

.melt-ship {
  display: flex;
  flex-wrap: wrap;
  gap: 4px 8px;
  align-items: center;
  margin: 0 0 12px;
}

.melt-contents {
  margin: 12px 0 16px;
}

.melt-muted {
  font-size: 0.85rem;
  color: var(--color-text-dim);
}
</style>
