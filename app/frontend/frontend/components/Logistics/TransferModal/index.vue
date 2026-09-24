<script lang="ts">
export default {
  name: "LogisticsTransferModal",
};
</script>

<script lang="ts" setup>
import Modal from "@/shared/components/AppModal/Inner/index.vue";
import Btn from "@/shared/components/base/Btn/index.vue";
import {
  BtnSizesEnum,
  BtnTonesEnum,
  BtnVariantsEnum,
} from "@/shared/components/base/Btn/types";
import FormInput from "@/shared/components/base/FormInput/index.vue";
import BaseSelect from "@/shared/components/base/Select/index.vue";
import { useI18n } from "@/shared/composables/useI18n";
import { useComlink } from "@/shared/composables/useComlink";
import { useAppNotifications } from "@/shared/composables/useAppNotifications";
import {
  type FilterOption,
  type InventoryStockPosition,
  type InventoryTransferCreateInput,
  FleetContractStateEnum,
  useFleetContracts,
} from "@/services/fyApi";
import { type FleetMember, fleetMembers } from "@/services/fyApi";
import { type BaseSelectParams } from "@/shared/components/base/Select/index.vue";
import { useSessionStore } from "@/frontend/stores/session";
import { FRIENDS_GROUP } from "@/frontend/composables/useTransferTargets";
import type {
  TransferSource,
  TransferTargetKind,
  TransferTargetOption,
} from "./types";

type Props = {
  source: TransferSource;
  // The positions the reader chose -- one row, or a bulk selection. Never the
  // whole inventory: a hold with fifty positions made a modal nobody could use.
  positions: InventoryStockPosition[];
  targets: TransferTargetOption[];
  // Where a person can be picked out of -- a fleet today, and whatever else
  // comes to mean "known" later, which lands here rather than as a new branch.
  memberFleets: { value: string; label: string }[];
  // Sending on a fleet's behalf, which is the only case where the reader's own
  // inventories are a separate kind from the ones being sent from.
  actingForFleet?: boolean;
  // Accepted friends, as `user:<username>` options. Held client-side rather
  // than searched: a friends list is short, and there is no second page of it.
  friendOptions?: { value: string; label: string }[];
  // The fleet this transfer is being sent on behalf of, when there is one. Its
  // own inventories are the immediate targets, so a delivery towards one of
  // its contracts has no recipient slug to read the fleet off.
  fleetSlug?: string;
  onSend: (payload: InventoryTransferCreateInput) => Promise<unknown>;
};

const props = defineProps<Props>();

const { t } = useI18n();
const sessionStore = useSessionStore();
const comlink = useComlink();
const { displayAlert } = useAppNotifications();

const submitting = ref(false);
const note = ref("");
const targetValue = ref<string | undefined>();

// The stock list is grouped per quality, so one position can arrive as several
// rows -- mined ore at two grades is two rows carrying one `id`. They are one
// thing to move, and the amount available is their sum, which is what
// `stock_positions` reports server-side and what the withdrawal is checked
// against. Collapsing them here is also what makes a bulk selection mean the
// position rather than one of its grades.
//
// Only positions holding something can move; an emptied one still resolves as a
// record, which is why it can appear in a list at all.
const movable = computed(() => {
  const byPosition = new Map<string, InventoryStockPosition>();

  props.positions.forEach((position) => {
    const existing = byPosition.get(position.id);

    if (existing) {
      existing.netQuantity =
        Number(existing.netQuantity) + Number(position.netQuantity);
      return;
    }

    byPosition.set(position.id, { ...position });
  });

  return [...byPosition.values()].filter(
    (position) => Number(position.netQuantity) > 0,
  );
});

// Trimming a bulk selection is removing a line, not unticking a box: the
// reader already chose these rows, so every one of them is going unless they
// say otherwise.
const removed = ref<Set<string>>(new Set());
const quantities = ref<Record<string, string>>({});

// Every line starts at its whole quantity: the reader picked these rows to move
// them, and moving all of it is the common case.
watchEffect(() => {
  movable.value.forEach((position) => {
    if (quantities.value[position.id] === undefined) {
      quantities.value[position.id] = String(position.netQuantity);
    }
  });
});

// Users and fleets are separate choices, not one mixed list: they are different
// kinds of address, and a list holding both makes the reader scan for which is
// which. The kind picks the list; the list is searchable, because a fleet can
// have hundreds of members.
//
// This iteration reaches only what the reader already shares a fleet with --
// which is also what a `known` transfer policy means server-side, so the picker
// and the gate agree on who counts. Arbitrary users and fleets are the API's to
// accept and are not offered here yet.
const KINDS: TransferTargetKind[] = [
  "inventory",
  "mine",
  "fleet",
  "user",
  "contract",
];

// Every kind is offered whether or not it holds anything, and an empty one says
// so. A kind that disappears when its list comes back empty leaves the reader
// with nothing to read: "I cannot send to a fleet" and "this build has no such
// thing" look identical, and the first is a state they can do something about.
//
// `mine` is the exception, because it is not a kind so much as a split: the
// reader's own inventories are only worth separating out when the ones being
// sent from belong to somebody else. Anywhere else it would list them twice.
//
// `contract` is only offered when there is one: most readers work no contract,
// and an always-empty kind would be noise on every transfer they make.
const availableKinds = computed(() =>
  KINDS.filter((kind) => {
    if (kind === "mine") return props.actingForFleet;
    if (kind === "contract")
      return props.targets.some((target) => target.kind === "contract");

    return true;
  }),
);

// A person is reached through a group -- a fleet, or the friends list -- so
// that kind is empty when there is no group to pick one out of, rather than
// when a list came back short.
const kindHasTargets = (kind: TransferTargetKind) =>
  kind === "user"
    ? props.memberFleets.length > 0
    : props.targets.some((target) => target.kind === kind);

const targetKind = ref<TransferTargetKind | undefined>();

// Offered always, but not *landed on* always: the modal opens on the first kind
// that holds something, so a reader whose only route is a fleet still finds it
// selected. Falling back to the first kind is what puts an empty list and its
// explanation in front of somebody with no route at all.
watchEffect(() => {
  if (targetKind.value && availableKinds.value.includes(targetKind.value))
    return;

  targetKind.value =
    availableKinds.value.find(kindHasTargets) ?? availableKinds.value[0];
});

const memberFleet = ref<string | undefined>(props.memberFleets[0]?.value);

// Searched on the server, not filtered out of one fixed page. A fleet can hold
// hundreds of members, and fetching the first hundred made everybody after them
// unreachable -- they could not be found because they were never fetched.
//
// `transferTargets` narrows the roster to the members who could actually
// receive, which is the same question `TransferGate` asks on the way in. It has
// to be the API's answer rather than a filter here for the same reason the
// search is: the list is paged, and thinning a page client-side would hide
// people the next page never reaches.
const fetchMembers = (params: BaseSelectParams<FilterOption>) =>
  fleetMembers(memberFleet.value ?? "", {
    q: { usernameCont: params.search || undefined },
    transferTargets: true,
  });

// The person list lives in the select rather than in `targetOptions`, so the
// watcher that re-picks when the kind changes never sees a fleet change.
// Without this, choosing somebody in fleet A and then switching to fleet B
// keeps A's username selected and sends the goods to them. It covers the
// friends group for the same reason.
watch(memberFleet, () => {
  if (targetKind.value !== "user") return;

  targetValue.value = undefined;
});

// Friends are a group you pick a person out of, exactly like a fleet -- so the
// group picker holds both and only the source of the names differs.
const pickingFriends = computed(() => memberFleet.value === FRIENDS_GROUP);

const formatMembers = (response: { items: FleetMember[] }) =>
  (response.items || [])
    .filter((member) => member.username !== sessionStore.currentUser?.username)
    .map((member) => ({
      label: member.nickname
        ? `${member.username} (${member.nickname})`
        : member.username,
      value: `user:${member.username}`,
    }));

const kindOptions = computed<FilterOption[]>(() =>
  availableKinds.value.map((kind) => ({
    value: kind,
    label: t(
      `labels.logistics.transferKinds.${
        kind === "inventory" && props.actingForFleet ? "fleetInventories" : kind
      }`,
    ),
  })),
);

const targetOptions = computed<FilterOption[]>(() =>
  props.targets
    .filter((target) => target.kind === targetKind.value)
    .map((target) => ({ value: target.value, label: target.label })),
);

// Picks the first option, and re-picks when a kind change leaves the old
// selection pointing into a list it is no longer part of. `immediate`, because
// the first list is exactly that case -- without it nothing is selected until
// the reader touches the kind picker.
watch(
  targetOptions,
  (options) => {
    if (options.some((option) => option.value === targetValue.value)) return;

    targetValue.value = options[0]?.value as string | undefined;
  },
  { immediate: true },
);

const noTargets = computed(
  () => !targetKind.value || !kindHasTargets(targetKind.value),
);

const selectedTarget = computed<TransferTargetOption | undefined>(() => {
  if (targetKind.value === "user") {
    const username = targetValue.value?.replace(/^user:/, "");

    if (!username) return undefined;

    return {
      kind: "user",
      value: targetValue.value as string,
      label: username,
      needsAnswer: true,
      payload: { recipientUsername: username },
    };
  }

  return props.targets.find((target) => target.value === targetValue.value);
});

// What the receiving side will see. A target the sender may write to is carried
// out on the spot; anything else has to be answered first.
const needsAnswer = computed(() => selectedTarget.value?.needsAnswer ?? false);

/*
 * Which fleet's contracts this delivery could count towards. A contract only
 * counts what a transfer naming it delivered -- `Contracts::Progress` reads the
 * link, not the goods -- so without this the bar never moves however exactly
 * the deposit matches the line.
 */
const contractFleetSlug = computed(() => {
  const payload = selectedTarget.value?.payload;
  if (!payload) return undefined;
  // A contract target already names its contract.
  if (payload.contractId) return undefined;
  if (payload.recipientFleetSlug) return payload.recipientFleetSlug;

  return payload.fleetInventoryId ? props.fleetSlug : undefined;
});

const { data: openContracts } = useFleetContracts(
  computed(() => contractFleetSlug.value ?? ""),
  computed(() => ({
    q: { stateIn: [FleetContractStateEnum.IN_PROGRESS] },
  })),
  {
    query: {
      retry: false,
      enabled: computed(() => !!contractFleetSlug.value),
    },
  },
);

const contractOptions = computed<FilterOption[]>(() => [
  { value: "", label: t("labels.logistics.noContract") },
  // Read only while it is being asked for: a disabled query still returns what
  // an earlier one cached, which would offer a second contract on top of the
  // one a contract target already names.
  ...(contractFleetSlug.value ? (openContracts.value?.items ?? []) : []).map(
    (contract) => ({
      value: contract.id,
      label: contract.title,
    }),
  ),
]);

const contractId = ref<string>("");

// A contract belongs to the fleet that posted it, so a change of address drops
// the choice rather than filing goods under a contract they never reach.
watch(contractFleetSlug, () => {
  contractId.value = "";
});

const chosen = computed(() =>
  movable.value.filter((position) => !removed.value.has(position.id)),
);

const multiple = computed(() => chosen.value.length > 1);

const quantityFor = (position: InventoryStockPosition) =>
  Number(quantities.value[position.id] ?? 0);

const overStock = (position: InventoryStockPosition) =>
  quantityFor(position) > Number(position.netQuantity);

// All-or-nothing, the same rule the API applies: one bad line refuses the whole
// shipment, so the button does not offer to send a partly valid one.
const invalid = computed(
  () =>
    !selectedTarget.value ||
    chosen.value.length === 0 ||
    chosen.value.some(
      (position) => quantityFor(position) <= 0 || overStock(position),
    ),
);

const maxFor = (position: InventoryStockPosition) =>
  Number(position.netQuantity);

const atMax = (position: InventoryStockPosition) =>
  quantityFor(position) === maxFor(position);

const resetToMax = (position: InventoryStockPosition) => {
  quantities.value[position.id] = String(maxFor(position));
};

const remove = (position: InventoryStockPosition) => {
  removed.value = new Set(removed.value).add(position.id);
};

const onSubmit = async () => {
  const target = selectedTarget.value;
  if (!target || invalid.value) return;

  submitting.value = true;

  try {
    await props.onSend({
      sourceInventoryId: props.source.id,
      lines: chosen.value.map((position) => ({
        positionId: position.id,
        quantity: quantityFor(position),
      })),
      note: note.value || undefined,
      contractId: contractId.value || undefined,
      ...target.payload,
    });

    comlink.emit("close-modal");
  } catch (error) {
    displayAlert({
      text:
        (
          error as {
            response?: {
              data?: { errors?: { messages?: { message?: string }[] }[] };
            };
          }
        )?.response?.data?.errors?.[0]?.messages?.[0]?.message ??
        t("messages.logistics.transfer.create.failure"),
    });
  } finally {
    submitting.value = false;
  }
};
</script>

<template>
  <Modal :title="t('headlines.logistics.transfer')">
    <form id="transfer-form" @submit.prevent="onSubmit">
      <BaseSelect
        v-if="kindOptions.length > 1"
        v-model="targetKind"
        name="targetKind"
        :options="kindOptions"
        :searchable="false"
        :label="t('labels.logistics.transferTargetKind')"
        data-test="transfer-target-kind"
      />

      <BaseSelect
        v-if="targetKind === 'user' && memberFleets.length > 1"
        v-model="memberFleet"
        name="memberFleet"
        searchable
        :options="memberFleets"
        :label="t('labels.logistics.transferFromFleet')"
        data-test="transfer-member-fleet"
      />

      <BaseSelect
        v-if="targetKind === 'user' && pickingFriends"
        v-model="targetValue"
        name="target"
        searchable
        :options="friendOptions"
        :label="t('labels.logistics.transferTarget')"
        data-test="transfer-target"
      />

      <!-- Held back until a group is chosen: the search names the fleet in its
           path, so an absent one asks the API for the members of "". -->
      <BaseSelect
        v-else-if="targetKind === 'user' && memberFleet"
        v-model="targetValue"
        name="target"
        searchable
        :query-fn="fetchMembers"
        :query-response-formatter="formatMembers"
        :label="t('labels.logistics.transferTarget')"
        data-test="transfer-target"
      />

      <BaseSelect
        v-else-if="targetKind !== 'user'"
        v-model="targetValue"
        name="target"
        searchable
        :options="targetOptions"
        :label="t('labels.logistics.transferTarget')"
        data-test="transfer-target"
      />

      <!-- Only when there is something to deliver towards: a fleet with no job
           running should not be asked about one. -->
      <BaseSelect
        v-if="contractOptions.length > 1"
        v-model="contractId"
        name="contract"
        searchable
        :options="contractOptions"
        :label="t('labels.logistics.towardsContract')"
        data-test="transfer-contract"
      />

      <p
        v-if="noTargets"
        class="transfer-empty"
        data-test="transfer-no-targets"
      >
        {{ t("labels.logistics.noTransferTargets") }}
      </p>

      <p v-if="needsAnswer" class="transfer-hint" data-test="transfer-hint">
        {{ t("messages.logistics.transfer.needsAnswer") }}
      </p>

      <p
        v-if="movable.length === 0"
        class="transfer-empty"
        data-test="transfer-empty"
      >
        {{ t("labels.logistics.noStock") }}
      </p>

      <div v-else class="transfer-lines">
        <div
          v-for="position in chosen"
          :key="position.id"
          class="transfer-line"
          :data-test="`transfer-line-${position.slug}`"
        >
          <span class="transfer-line-name">{{ position.name }}</span>

          <div class="transfer-line-amount">
            <FormInput
              v-model="quantities[position.id]"
              type="number"
              no-placeholder
              inline
              :min="0"
              :max="maxFor(position)"
              :name="`quantity-${position.id}`"
              :label="t('labels.logistics.quantity')"
            />
            <span class="transfer-line-unit">
              {{ t(`labels.logistics.units.${position.unit}`) }}
            </span>
            <span class="transfer-line-max">
              / {{ position.netQuantity }}
            </span>

            <Btn
              v-if="!atMax(position)"
              :size="BtnSizesEnum.SM"
              :variant="BtnVariantsEnum.BARE"
              :aria-label="t('actions.logistics.resetToMax')"
              :title="t('actions.logistics.resetToMax')"
              :data-test="`transfer-reset-${position.slug}`"
              @click="resetToMax(position)"
            >
              <i class="fa-duotone fa-arrow-rotate-left" />
            </Btn>

            <Btn
              v-if="multiple"
              :size="BtnSizesEnum.SM"
              :variant="BtnVariantsEnum.BARE"
              :tone="BtnTonesEnum.DANGER"
              :aria-label="t('actions.logistics.removeLine')"
              :title="t('actions.logistics.removeLine')"
              :data-test="`transfer-remove-${position.slug}`"
              @click="remove(position)"
            >
              <i class="fa fa-times" />
            </Btn>
          </div>

          <p
            v-if="overStock(position)"
            class="transfer-line-error"
            :data-test="`transfer-over-stock-${position.slug}`"
          >
            {{ t("labels.logistics.overStock") }}
          </p>
        </div>
      </div>

      <FormInput
        v-model="note"
        name="note"
        no-placeholder
        :label="t('labels.logistics.transferNote')"
      />
    </form>

    <template #footer>
      <div class="float-sm-right">
        <Btn
          :loading="submitting"
          :disabled="invalid"
          :size="BtnSizesEnum.LG"
          data-test="transfer-submit"
          @click="onSubmit"
        >
          {{
            needsAnswer
              ? t("actions.logistics.sendTransfer")
              : t("actions.logistics.moveStock")
          }}
        </Btn>
      </div>
    </template>
  </Modal>
</template>

<style lang="scss" scoped>
.transfer-hint {
  margin-bottom: 1rem;
  opacity: 0.75;
}

.transfer-lines {
  margin-bottom: 1.5rem;
}

.transfer-line {
  padding: 0.5rem 0;

  &:not(:last-child) {
    border-bottom: 1px solid rgb(255 255 255 / 8%);
  }
}

.transfer-line-name {
  display: block;
  margin-bottom: 0.25rem;
  font-weight: 600;
}

.transfer-line-amount {
  display: flex;
  gap: 0.5rem;
  align-items: center;
}

.transfer-line-unit,
.transfer-line-max {
  white-space: nowrap;
  opacity: 0.7;
}

.transfer-empty {
  margin: 0.5rem 0;
  opacity: 0.75;
}

.transfer-line-error {
  margin: 0.25rem 0 0;
  color: var(--color-danger, #d11b45);
}
</style>
