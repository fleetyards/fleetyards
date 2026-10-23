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
import PickList, {
  type PickListItem,
} from "@/frontend/components/Hangar/Planner/PickList/index.vue";
import { usePlanMoney } from "@/frontend/components/Hangar/Planner/format";
import Chip from "@/shared/components/base/Chip/index.vue";
import { ChipStatesEnum } from "@/shared/components/base/Chip/types";
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
  melt?: HangarPlanMelt;
};

const props = defineProps<Props>();

const { t } = useI18n();
const { displayAlert } = useAppNotifications();
const comlink = useComlink();
const { updatePlan } = useHangarPlanCache();

const { money } = usePlanMoney();

const { data: resources, isLoading } = useHangarPlanResources(
  () => props.planId,
);

const submitting = ref(false);
const vehicleId = ref<string | null>(props.melt?.vehicleId ?? null);
const valueOverride = ref<string>(props.melt?.valueOverride?.toString() ?? "");

const touched = ref(false);
watch([vehicleId, valueOverride], () => {
  touched.value = true;
});
useModalDirty(touched);

const freeVehicles = computed(() =>
  (resources.value?.vehicles ?? []).filter((vehicle) => !vehicle.usedBy),
);

// RSI says per pledge whether it melts, but only for ships the hangar sync
// read; anyone who keeps their hangar by hand can still melt any ship.
const meltableCount = computed(
  () => freeVehicles.value.filter((vehicle) => vehicle.meltable).length,
);

const meltableOnly = ref(false);

// Filtered by default once the sync has said which ships melt.
watch(
  meltableCount,
  (count, before) => {
    if (count && !before) meltableOnly.value = true;
  },
  { immediate: true },
);

const meltable = computed(() =>
  meltableOnly.value
    ? freeVehicles.value.filter((vehicle) => vehicle.meltable)
    : freeVehicles.value,
);

type Vehicle = (typeof freeVehicles.value)[number];

const meltBadge = (vehicle: Vehicle) => {
  if (vehicle.meltable === false)
    return t("hangarPlanner.meltList.notMeltable");
  if (vehicle.meltable === null || vehicle.meltable === undefined) {
    return t("hangarPlanner.meltList.notSynced");
  }
  return undefined;
};

const inPackage = (vehicle: Vehicle) =>
  (vehicle.pledgeItemCount ?? 0) > 1 ||
  vehicle.pledgeShips.length > 0 ||
  vehicle.pledgeItems.length > 0;

const packageLabel = (vehicle: Vehicle) => {
  if (!inPackage(vehicle)) return undefined;
  if (vehicle.pledgeName) {
    return t("hangarPlanner.meltList.inPackage", { name: vehicle.pledgeName });
  }
  return t("hangarPlanner.meltList.wholePledge", {
    count: vehicle.pledgeItemCount ?? 0,
  });
};

const creditOf = (vehicle: Vehicle) =>
  vehicle.meltValue ?? vehicle.model.pledgePrice ?? null;

const vehicleItems = computed<PickListItem[]>(() =>
  meltable.value.map((vehicle) => ({
    id: vehicle.id,
    title: vehicle.name || vehicle.model.name,
    meta:
      [vehicle.name ? vehicle.model.name : undefined, packageLabel(vehicle)]
        .filter(Boolean)
        .join(" · ") || undefined,
    keywords: [
      ...vehicle.pledgeShips.map((ship) => ship.model.name),
      ...vehicle.pledgeItems.map((item) => item.name),
    ].join(" "),
    price:
      typeof vehicle.meltValue === "number"
        ? t("hangarPlanner.meltList.credit", {
            value: money(vehicle.meltValue),
          })
        : t("hangarPlanner.meltList.estimate", {
            value: money(creditOf(vehicle)),
          }),
    sortPrice: creditOf(vehicle),
    badge: meltBadge(vehicle),
  })),
);

const picked = computed(() =>
  freeVehicles.value.find((vehicle) => vehicle.id === vehicleId.value),
);

// Editing a melt, its ship is taken by the melt itself and not in the free list.
const meltedVehicle = computed(() =>
  (resources.value?.vehicles ?? []).find(
    (vehicle) => vehicle.id === vehicleId.value,
  ),
);

const contents = computed(() => {
  const vehicle = meltedVehicle.value;
  if (!vehicle || !inPackage(vehicle)) return undefined;

  const entries = [
    ...vehicle.pledgeShips.map((ship) => ({
      id: ship.id,
      name: ship.name ? `${ship.name} (${ship.model.name})` : ship.model.name,
      quantity: 1,
      icon: "fa-light fa-rocket",
    })),
    ...vehicle.pledgeItems.map((item) => ({
      id: item.id,
      name: item.name,
      quantity: item.quantity,
      icon: "fa-light fa-box",
    })),
  ];
  const listed = 1 + entries.reduce((sum, entry) => sum + entry.quantity, 0);
  // RSI counts what the sync keeps no record of, such as the game package or
  // insurance-only items.
  const unlisted = Math.max((vehicle.pledgeItemCount ?? 0) - listed, 0);

  return { name: vehicle.pledgeName, entries, unlisted };
});

const placeholder = computed(() => {
  const credit = picked.value ? creditOf(picked.value) : props.melt?.value;
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
      <template v-if="!melt">
        <span class="melt-label">{{ t("hangarPlanner.fields.meltShip") }}</span>
        <PickList
          v-model="vehicleId"
          name="vehicleId"
          :items="vehicleItems"
          :loading="isLoading"
          :empty="
            meltableOnly
              ? t('hangarPlanner.meltList.none')
              : t('hangarPlanner.meltList.noShips')
          "
        >
          <template #filters>
            <div class="melt-filters">
              <Chip
                :state="
                  meltableOnly
                    ? ChipStatesEnum.INCLUDED
                    : ChipStatesEnum.NEUTRAL
                "
                :count="meltableCount"
                data-test="hangar-plan-melt-filter-meltable"
                @toggle="meltableOnly = !meltableOnly"
              >
                {{ t("hangarPlanner.meltList.meltableOnly") }}
              </Chip>
            </div>
          </template>
        </PickList>
      </template>
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
        <ul class="melt-contents__list">
          <li
            v-for="entry in contents.entries"
            :key="entry.id"
            class="melt-contents__item"
          >
            <i :class="entry.icon" aria-hidden="true" />
            <span>{{ entry.name }}</span>
            <span v-if="entry.quantity > 1" class="melt-contents__quantity">
              ×{{ entry.quantity }}
            </span>
          </li>
          <li
            v-if="contents.unlisted"
            class="melt-contents__item melt-contents__item--dim"
          >
            {{
              t("hangarPlanner.meltList.unlisted", {
                count: contents.unlisted,
              })
            }}
          </li>
        </ul>
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
        :disabled="!melt && !vehicleId"
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

.melt-filters {
  display: flex;
  flex-wrap: wrap;
  gap: 6px;
}

.melt-contents {
  margin: 12px 0 16px;
}

.melt-contents__list {
  display: flex;
  flex-direction: column;
  gap: 4px;
  margin: 0;
  padding: 0;
  list-style: none;
}

.melt-contents__item {
  display: flex;
  gap: 8px;
  align-items: baseline;
  font-size: 0.9rem;

  i {
    width: 1rem;
    color: var(--color-text-dim);
    text-align: center;
  }
}

.melt-contents__item--dim,
.melt-contents__quantity {
  color: var(--color-text-dim);
}

.melt-muted {
  margin: 8px 0 16px;
  font-size: 0.85rem;
  color: var(--color-text-dim);
}
</style>
