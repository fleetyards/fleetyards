<script lang="ts">
export default {
  name: "HangarPlannerSlotShipsModal",
};
</script>

<script lang="ts" setup>
import type { Component } from "vue";
import { useRouter } from "vue-router";
import Modal from "@/shared/components/AppModal/Inner/index.vue";
import Btn from "@/shared/components/base/Btn/index.vue";
import {
  BtnSizesEnum,
  BtnTonesEnum,
  BtnVariantsEnum,
} from "@/shared/components/base/Btn/types";
import { useCandidateSpecs } from "@/frontend/components/Hangar/Planner/candidateSpecs";
import fallbackImage from "@/images/fallback/store_image.webp";
import { useI18n } from "@/shared/composables/useI18n";
import { useComlink } from "@/shared/composables/useComlink";
import { useAppNotifications } from "@/shared/composables/useAppNotifications";
import { useHangarPlanCache } from "@/frontend/composables/useHangarPlanCache";
import {
  type HangarPlan,
  type HangarPlanCandidate,
  type HangarPlanSlot,
  HangarPlanSlotStateEnum,
  useChooseHangarPlanSlotCandidate,
  useDestroyHangarPlanCandidate,
  useDestroyHangarPlanSlot,
  useHangarPlan,
} from "@/services/fyApi";

type Props = {
  planId: string;
  slot: HangarPlanSlot;
};

const props = defineProps<Props>();

const { t } = useI18n();
const comlink = useComlink();
const { displayAlert } = useAppNotifications();
const { updatePlan } = useHangarPlanCache();

// Read from the plan as it stands, so removing a ship shows here at once.
const { data: plan } = useHangarPlan(computed(() => props.planId));

const current = computed(
  () =>
    plan.value?.slots.find((entry) => entry.id === props.slot.id) ?? props.slot,
);

const undecided = computed(
  () => current.value.state === HangarPlanSlotStateEnum.UNDECIDED,
);

const { specs } = useCandidateSpecs(() => current.value.candidates);

const router = useRouter();

// Side by side on the compare page, in a tab of its own so the plan stays
// where it was.
const compareHref = computed(() =>
  current.value.candidates.length > 1
    ? router.resolve({
        name: "compare",
        query: {
          models: current.value.candidates.map(
            (candidate) => candidate.model.slug,
          ),
        },
      }).href
    : undefined,
);

const meta = (candidate: HangarPlanCandidate) =>
  [
    candidate.paintName,
    candidate.ownedCount
      ? t("hangarPlanner.ownedCount", { count: candidate.ownedCount })
      : undefined,
    candidate.model.onSale ? undefined : t("hangarPlanner.notOnSale"),
  ]
    .filter(Boolean)
    .join(" · ");

const choose = useChooseHangarPlanSlotCandidate();
const destroyCandidate = useDestroyHangarPlanCandidate();
const destroySlot = useDestroyHangarPlanSlot();

const busy = ref(false);

const run = async (request: () => Promise<HangarPlan>, close = false) => {
  busy.value = true;

  try {
    updatePlan(await request());
    if (close) comlink.emit("close-modal", true);
  } catch {
    displayAlert({ text: t("hangarPlanner.messages.saveFailed") });
  } finally {
    busy.value = false;
  }
};

const chooseCandidate = (candidate: HangarPlanCandidate) =>
  run(
    () =>
      choose.mutateAsync({
        hangarPlanId: props.planId,
        id: props.slot.id,
        data: { candidateId: candidate.id },
      }),
    true,
  );

const removeCandidate = (candidate: HangarPlanCandidate) =>
  run(() =>
    destroyCandidate.mutateAsync({
      hangarPlanId: props.planId,
      id: candidate.id,
    }),
  );

const removeSlot = () =>
  run(
    () =>
      destroySlot.mutateAsync({
        hangarPlanId: props.planId,
        id: props.slot.id,
      }),
    true,
  );

const openModal = (component: () => Promise<Component>) =>
  comlink.emit("open-modal", {
    component,
    props: { planId: props.planId, slot: current.value },
  });

const addShips = () =>
  openModal(
    () =>
      import("@/frontend/components/Hangar/Planner/CandidatePickerModal/index.vue"),
  );

const editSettings = () =>
  openModal(
    () => import("@/frontend/components/Hangar/Planner/SlotModal/index.vue"),
  );
</script>

<template>
  <Modal :title="current.label" :eyebrow="t('hangarPlanner.editSlot')">
    <p v-if="undecided" class="slot-ships__hint">
      {{ t("hangarPlanner.chooseHint") }}
    </p>
    <p v-else-if="!current.candidates.length" class="slot-ships__hint">
      {{ t("hangarPlanner.openSlotHint") }}
    </p>

    <ul class="slot-ships">
      <li
        v-for="candidate in current.candidates"
        :key="candidate.id"
        class="slot-ship"
        data-test="hangar-plan-slot-ship"
      >
        <img
          :src="candidate.model.image?.smallUrl || fallbackImage"
          alt=""
          class="slot-ship__image"
          loading="lazy"
        />
        <span class="slot-ship__title">
          <strong>{{ candidate.model.name }}</strong>
          <span
            v-if="candidate.model.manufacturerName"
            class="slot-ship__muted"
          >
            {{ candidate.model.manufacturerName }}
          </span>
        </span>
        <dl class="slot-ship__specs">
          <div
            v-for="spec in specs(candidate)"
            :key="spec.key"
            class="slot-ship__spec"
          >
            <dt>{{ t(`hangarPlanner.specs.${spec.key}`) }}</dt>
            <dd>
              {{ spec.value }}
              <span v-if="undecided && spec.best" class="slot-ship__best">
                {{ t("hangarPlanner.specs.best") }}
              </span>
            </dd>
          </div>
        </dl>
        <span v-if="meta(candidate)" class="slot-ship__muted">
          {{ meta(candidate) }}
        </span>
        <span v-if="!candidate.matchesFilters" class="slot-ship__warning">
          {{ t("hangarPlanner.outsideFilters") }}
        </span>
        <span class="slot-ship__actions">
          <Btn
            v-if="undecided"
            :size="BtnSizesEnum.MD"
            :disabled="busy"
            class="slot-ship__choose"
            data-test="hangar-plan-slot-ship-choose"
            @click="chooseCandidate(candidate)"
          >
            <i class="fa-light fa-check" />
            {{ t("hangarPlanner.choose") }}
          </Btn>
          <Btn
            :size="BtnSizesEnum.XS"
            :variant="BtnVariantsEnum.BARE"
            :tone="BtnTonesEnum.DANGER"
            :disabled="busy"
            :aria-label="t('hangarPlanner.removeCandidate')"
            :title="t('hangarPlanner.removeCandidate')"
            data-test="hangar-plan-slot-ship-remove"
            @click="removeCandidate(candidate)"
          >
            <i class="fa-light fa-xmark" />
          </Btn>
        </span>
      </li>
      <li class="slot-ships__add">
        <Btn
          :size="BtnSizesEnum.SM"
          data-test="hangar-plan-slot-ships-add"
          @click="addShips"
        >
          <i class="fa-light fa-plus" />
          {{ t("hangarPlanner.addShips") }}
        </Btn>
      </li>
    </ul>

    <template #footer-start>
      <Btn
        :variant="BtnVariantsEnum.BARE"
        :tone="BtnTonesEnum.DANGER"
        :confirm="t('hangarPlanner.confirmRemoveSlot')"
        :disabled="busy"
        data-test="hangar-plan-slot-ships-remove-slot"
        @click="removeSlot"
      >
        <i class="fa-light fa-trash" />
        {{ t("hangarPlanner.removeSlot") }}
      </Btn>
    </template>
    <template #footer>
      <Btn
        v-if="compareHref"
        :href="compareHref"
        data-test="hangar-plan-slot-ships-compare"
      >
        <i class="fa-light fa-code-compare" />
        {{ t("actions.compare.ships") }}
      </Btn>
      <Btn data-test="hangar-plan-slot-ships-settings" @click="editSettings">
        <i class="fa-light fa-sliders" />
        {{ t("hangarPlanner.slotSettings") }}
      </Btn>
    </template>
  </Modal>
</template>

<style lang="scss" scoped>
.slot-ships__hint {
  margin: 0 0 12px;
  color: var(--color-text-dim);
}

.slot-ships {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
  gap: 12px;
  margin: 0;
  padding: 0;
  list-style: none;
}

.slot-ship {
  display: flex;
  flex-direction: column;
  gap: 8px;
  padding: 12px;
  border: 1px solid var(--color-edge-soft);
  border-radius: 12px;
  background: var(--color-control);
}

.slot-ships__add {
  display: flex;
  align-items: center;
  justify-content: center;
  min-height: 120px;
  border: 1px dashed var(--color-edge-soft);
  border-radius: 12px;
}

.slot-ship__image {
  width: 100%;
  height: 110px;
  object-fit: cover;
  border-radius: 8px;
}

.slot-ship__title {
  display: flex;
  flex-direction: column;

  strong {
    color: var(--color-lifted);
  }
}

.slot-ship__specs {
  margin: 0;
}

.slot-ship__spec {
  display: flex;
  justify-content: space-between;
  padding: 6px 0;
  border-top: 1px solid var(--color-edge-faint);

  dt {
    font-family: "Orbitron", tahoma, sans-serif;
    font-size: 10px;
    font-weight: 400;
    letter-spacing: 0.16em;
    text-transform: uppercase;
    color: var(--color-text-dim);
  }

  dd {
    margin: 0;
    font-size: 13.5px;
    font-weight: 600;
    color: var(--color-lifted);
  }
}

.slot-ship__best {
  margin-left: 4px;
  font-size: 0.75rem;
  color: var(--color-success);
}

.slot-ship__muted {
  font-size: 0.8rem;
  color: var(--color-text-dim);
}

.slot-ship__warning {
  font-size: 0.8rem;
  color: var(--color-warning);
}

.slot-ship__actions {
  display: flex;
  gap: 4px;
  align-items: center;
  justify-content: flex-end;
  margin-top: auto;
}

// Picking one is what an undecided slot is waiting for, so the button takes
// the card's width rather than sitting small beside the remove icon.
.slot-ship__choose {
  flex: 1;
}
</style>
