<script lang="ts">
export default {
  name: "FleetEventsShipExpandHint",
};
</script>

<script lang="ts" setup>
import Btn from "@/shared/components/base/Btn/index.vue";
import { BtnSizesEnum } from "@/shared/components/base/Btn/types";
import type {
  Fleet,
  FleetEvent,
  FleetEventShip,
  FleetEventSlot,
  FleetEventTeam,
} from "@/services/fyApi";
import { useI18n } from "@/shared/composables/useI18n";
import { useComlink } from "@/shared/composables/useComlink";

type Props = {
  fleet: Fleet;
  event: FleetEvent;
  team: FleetEventTeam;
  ship: FleetEventShip;
};

const props = defineProps<Props>();

const { t } = useI18n();
const comlink = useComlink();

const slots = computed<FleetEventSlot[]>(
  () => (props.ship.slots ?? []) as FleetEventSlot[],
);

// Pick the first active signup whose picked vehicle has more positions than
// the ship currently has slots — that's the candidate to expand from.
const candidate = computed(() => {
  for (const slot of slots.value) {
    for (const signup of slot.signups ?? []) {
      if (signup.status === "withdrawn") continue;
      const model = signup.vehicle?.model as
        | {
            id?: string;
            slug?: string;
            name?: string;
            positionCount?: number | null;
          }
        | undefined;
      if (!model?.id || !model.slug) continue;
      const count = model.positionCount ?? 0;
      if (count > slots.value.length) return model;
    }
  }
  return null;
});

const extraSeats = computed(() =>
  candidate.value
    ? (candidate.value.positionCount ?? 0) - slots.value.length
    : 0,
);

const openExpandModal = () => {
  if (!candidate.value?.id || !candidate.value.slug) return;
  comlink.emit("open-modal", {
    component: () =>
      import("@/frontend/components/Fleets/Events/EventShipExpandModal/index.vue"),
    props: {
      fleet: props.fleet,
      event: props.event,
      team: props.team,
      ship: props.ship,
      modelId: candidate.value.id,
      modelSlug: candidate.value.slug,
      modelName: candidate.value.name ?? "",
    },
  });
};
</script>

<template>
  <div v-if="candidate" class="ship-expand-hint">
    <i class="fa-light fa-square-plus" />
    <span>
      {{
        t("labels.fleets.events.expandHint", {
          model: candidate.name,
          count: extraSeats,
        })
      }}
    </span>
    <Btn :size="BtnSizesEnum.SMALL" inline @click="openExpandModal">
      {{ t("actions.fleets.events.addSeats") }}
    </Btn>
  </div>
</template>

<style lang="scss" scoped>
.ship-expand-hint {
  display: flex;
  align-items: center;
  gap: 0.5rem;
  margin: 0.4rem 0 0.6rem;
  padding: 0.4rem 0.7rem;
  font-size: 0.82rem;
  color: var(--accent, #4aa);
  background: rgba(74, 170, 170, 0.08);
  border: 1px solid rgba(74, 170, 170, 0.4);
  border-radius: 4px;

  i {
    color: inherit;
  }

  span {
    flex: 1;
  }
}
</style>
