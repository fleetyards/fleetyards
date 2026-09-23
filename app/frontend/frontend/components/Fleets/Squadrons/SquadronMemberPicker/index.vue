<script lang="ts">
export default {
  name: "FleetSquadronMemberPicker",
};
</script>

<script lang="ts" setup>
import Modal from "@/shared/components/AppModal/Inner/index.vue";
import Btn from "@/shared/components/base/Btn/index.vue";
import {
  BtnSizesEnum,
  BtnVariantsEnum,
} from "@/shared/components/base/Btn/types";
import FormInput from "@/shared/components/base/FormInput/index.vue";
import Avatar from "@/shared/components/Avatar/index.vue";
import Chip from "@/shared/components/base/Chip/index.vue";
import { ChipStatesEnum } from "@/shared/components/base/Chip/types";
import Empty from "@/shared/components/Empty/index.vue";
import { EmptyVariantsEnum } from "@/shared/components/Empty/types";
import Loader from "@/shared/components/Loader/index.vue";
import { refDebounced } from "@vueuse/core";
import { useI18n } from "@/shared/composables/useI18n";
import { useAppNotifications } from "@/shared/composables/useAppNotifications";
import { useComlink } from "@/shared/composables/useComlink";
import {
  type Fleet,
  type FleetSquadron,
  type FleetMember,
  type FleetMembersParams,
  useFleetMembers,
  useCreateFleetSquadronMember,
  useDestroyFleetSquadronMember,
} from "@/services/fyApi";

type Props = {
  fleet: Fleet;
  squadron: FleetSquadron;
};

const props = defineProps<Props>();

const { t } = useI18n();
const { displaySuccess, displayAlert } = useAppNotifications();
const comlink = useComlink();

const search = ref("");
const debouncedSearch = refDebounced(search, 300);

const page = ref(1);

const queryParams = computed<FleetMembersParams>(() => ({
  page: String(page.value),
  perPage: "30",
  q: {
    usernameCont: debouncedSearch.value || undefined,
    stateIn: ["accepted"],
  } as never,
}));

const { data, isLoading } = useFleetMembers(
  computed(() => props.fleet.slug),
  queryParams,
);

/*
 * Accumulated rather than replaced, so "load more" grows the list the way the
 * ship picker's does. A new search starts the list again -- page 1 of a
 * different question is not page 4 of this one.
 */
const records = ref<FleetMember[]>([]);

watch(debouncedSearch, () => {
  page.value = 1;
  records.value = [];
});

watch(
  data,
  (value) => {
    if (!value) return;

    const items = value.items ?? [];

    records.value =
      page.value === 1
        ? items
        : [
            ...records.value,
            ...items.filter(
              (item) => !records.value.some((held) => held.id === item.id),
            ),
          ];
  },
  { immediate: true },
);

const totalPages = computed(
  () => data.value?.meta?.pagination?.totalPages ?? 1,
);

const hasMore = computed(() => page.value < totalPages.value);

const loadMore = () => {
  page.value += 1;
};

/*
 * Who is in it now. The picker shows them ticked rather than hiding them,
 * because taking somebody out of a squadron has to be possible somewhere and
 * this is where the roster is already in front of you -- which matters more
 * now that a member holds only one squadron, so moving them means taking them
 * out of the one they have.
 */
const alreadyIn = (member: FleetMember) =>
  (member.squadrons ?? []).some(
    (squadron) => squadron.id === props.squadron.id,
  );

/*
 * A member belongs to one squadron, so somebody who already has one cannot be
 * added to another. Teams are outside that on both sides: joining one is never
 * refused, and being on one never blocks anything.
 *
 * The server refuses it either way -- this is so the refusal is visible before
 * the click rather than as a count of failures afterwards, and so it can name
 * the squadron standing in the way.
 */
const blockedBy = (member: FleetMember) => {
  if (props.squadron.team) return undefined;

  return (member.squadrons ?? []).find(
    (squadron) => !squadron.team && squadron.id !== props.squadron.id,
  );
};

/*
 * The squadron's own members first, then everybody else, alphabetically within
 * each. Ordered by who was in it when the modal opened rather than by what is
 * ticked now: re-sorting on every tick moves the next card under the pointer.
 */
const options = computed(() =>
  [...records.value].sort((a, b) => {
    if (wasIn(a) !== wasIn(b)) return wasIn(a) ? -1 : 1;

    return (a.username ?? "").localeCompare(b.username ?? "");
  }),
);

// Seeded from the squadron as the roster loads, so the ticks are the state it
// is in and the submit is the difference. Only members not yet accounted for
// are added, so a page 2 that arrives later does not undo an untick on page 1.
const selection = ref<FleetMember[]>([]);
const seeded = ref<string[]>([]);

watch(
  records,
  (members) => {
    const fresh = members.filter(
      (member) => alreadyIn(member) && !seeded.value.includes(member.id),
    );

    seeded.value = [...seeded.value, ...fresh.map((member) => member.id)];
    selection.value = [...selection.value, ...fresh];
  },
  { immediate: true },
);

const wasIn = (member: FleetMember) => seeded.value.includes(member.id);

const isSelected = (member: FleetMember) =>
  selection.value.some((held) => held.id === member.id);

const toggle = (member: FleetMember) => {
  selection.value = isSelected(member)
    ? selection.value.filter((held) => held.id !== member.id)
    : [...selection.value, member];
};

const remove = (id: string) => {
  selection.value = selection.value.filter((held) => held.id !== id);
};

const resetSelection = () => {
  selection.value = records.value.filter(wasIn);
};

const submitting = ref(false);

const createMutation = useCreateFleetSquadronMember();
const destroyMutation = useDestroyFleetSquadronMember();

// The difference between what is ticked and what was, which is what the submit
// has to write. Ticking somebody who was already in is not a request.
const toAdd = computed(() =>
  selection.value.filter((member) => !wasIn(member)),
);

const toRemove = computed(() =>
  records.value.filter((member) => wasIn(member) && !isSelected(member)),
);

const pending = computed(() => toAdd.value.length + toRemove.value.length);

/*
 * One request per person, and a failure part-way through leaves what already
 * landed in place: they are separate rows, and rolling them back would be a
 * third way to change a squadron's roster that nobody asked for. The message
 * says how many did not.
 */
const onSubmit = async () => {
  if (!pending.value) return;

  submitting.value = true;

  const results = await Promise.allSettled([
    ...toAdd.value.map((member) =>
      createMutation.mutateAsync({
        fleetSlug: props.fleet.slug,
        fleetSquadronSlug: props.squadron.slug,
        data: { username: member.username },
      }),
    ),
    ...toRemove.value.map((member) =>
      destroyMutation.mutateAsync({
        fleetSlug: props.fleet.slug,
        fleetSquadronSlug: props.squadron.slug,
        username: member.username,
      }),
    ),
  ]);

  submitting.value = false;

  const landed = results.filter(
    (result) => result.status === "fulfilled",
  ).length;
  const failed = results.length - landed;

  if (landed) {
    comlink.emit("fleet-squadron-members-updated");
    displaySuccess({
      text: t("messages.fleet.squadrons.members.save.success", {
        count: landed,
      }),
    });
  }

  if (failed) {
    displayAlert({
      text: t("messages.fleet.squadrons.members.save.failure", {
        count: failed,
      }),
    });
    return;
  }

  comlink.emit("close-modal");
};
</script>

<template>
  <Modal :title="t('headlines.fleets.squadrons.manageMembers')">
    <form
      id="fleet-squadron-members-form"
      class="member-picker"
      @submit.prevent="onSubmit"
    >
      <div class="member-picker__header">
        <FormInput
          v-model="search"
          name="squadron-member-search"
          class="member-picker__search"
          :label="t('labels.fleet.squadrons.searchMembers')"
          :placeholder="t('labels.fleet.squadrons.searchMembers')"
          icon="fa-light fa-magnifying-glass"
          autofocus
          no-label
          clearable
        />
      </div>

      <Loader v-if="isLoading && !records.length" :loading="true" inline />

      <div v-else-if="options.length" class="member-picker__grid">
        <button
          v-for="member in options"
          :key="member.id"
          v-tooltip="
            blockedBy(member)
              ? t('labels.fleet.squadrons.blockedBy', {
                  squadron: blockedBy(member)?.name,
                })
              : undefined
          "
          type="button"
          class="member-picker__card"
          :class="{
            'member-picker__card--selected': isSelected(member),
            'member-picker__card--blocked': blockedBy(member),
          }"
          :disabled="!!blockedBy(member)"
          :data-test="`squadron-member-option-${member.username}`"
          @click="toggle(member)"
        >
          <Avatar :avatar="member.avatar?.smallUrl" size="small" />
          <span class="member-picker__name">{{ member.username }}</span>
          <i
            v-if="blockedBy(member)"
            class="fa-solid fa-ban member-picker__tick"
          />
          <i
            v-else
            class="fa-solid member-picker__tick"
            :class="isSelected(member) ? 'fa-circle-check' : 'fa-circle-plus'"
          />
        </button>
      </div>

      <Empty
        v-else-if="!isLoading"
        :variant="EmptyVariantsEnum.DEFAULT"
        :name="t('labels.fleet.squadrons.availableMembers')"
        inline
        hide-actions
      />

      <div v-if="hasMore" class="member-picker__more">
        <Btn
          :loading="isLoading"
          :variant="BtnVariantsEnum.BARE"
          @click="loadMore"
        >
          {{ t("actions.loadMore") }}
        </Btn>
      </div>

      <!-- In the scroll area rather than the footer, for the reason the ship
           picker gives: the footer is sized for one row of actions and a tray
           of chips there pushes the submit button out of the viewport. -->
      <!-- What the squadron will hold, not what is being added: the tray is the
           answer the submit writes. -->
      <div v-if="selection.length" class="member-picker__tray">
        <Chip
          v-for="member in selection"
          :key="member.id"
          :state="ChipStatesEnum.INCLUDED"
          @toggle="remove(member.id)"
        >
          {{ member.username }}
        </Chip>
      </div>
    </form>

    <template #footer>
      <div class="member-picker__actions">
        <span class="member-picker__selected">
          {{
            t("labels.fleet.squadrons.selectedMembers", {
              count: selection.length,
            })
          }}
        </span>
        <Btn
          v-if="pending"
          :variant="BtnVariantsEnum.BARE"
          data-test="squadron-members-reset"
          @click="resetSelection"
        >
          {{ t("actions.reset") }}
        </Btn>
        <Btn
          :loading="submitting"
          :disabled="!pending"
          :size="BtnSizesEnum.LG"
          data-test="squadron-save-members"
          @click="onSubmit"
        >
          {{ t("actions.fleet.squadrons.saveMembers", { count: pending }) }}
        </Btn>
      </div>
    </template>
  </Modal>
</template>

<style lang="scss" scoped>
.member-picker__header {
  margin-bottom: 12px;
}

.member-picker__grid {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(220px, 1fr));
  gap: 8px;
}

.member-picker__card {
  display: flex;
  align-items: center;
  gap: 10px;
  padding: 8px 12px;
  background-color: var(--color-control, rgb(39 43 48 / 0.9));
  border: 1px solid var(--color-edge-soft, rgb(122 130 136 / 0.28));
  border-radius: var(--radius-control, 8px);
  color: var(--color-text, #c8c8c8);
  text-align: left;
  cursor: pointer;
  transition: background-color 150ms ease;

  &:hover,
  &:focus-visible {
    background-color: var(--color-control-hover, rgb(52 58 64 / 0.95));
  }

  &--selected {
    border-color: var(--color-primary, #428bca);
  }

  // Dimmed rather than hidden: the reason somebody is not on the list is worth
  // seeing, and the tooltip on the card is what carries it.
  &--blocked {
    cursor: not-allowed;
    opacity: 0.45;

    &:hover,
    &:focus-visible {
      background-color: var(--color-control, rgb(39 43 48 / 0.9));
    }
  }
}

.member-picker__name {
  flex: 1;
  min-width: 0;
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}

.member-picker__tick {
  flex: none;
  color: var(--color-muted, #7a8288);
}

.member-picker__card--selected .member-picker__tick {
  color: var(--color-primary, #428bca);
}

.member-picker__more {
  display: flex;
  justify-content: center;
  margin-top: 12px;
}

.member-picker__tray {
  display: flex;
  flex-wrap: wrap;
  gap: 6px;
  margin-top: 16px;
  padding-top: 12px;
  border-top: 1px solid var(--color-edge-soft, rgb(122 130 136 / 0.28));
}

.member-picker__actions {
  display: flex;
  align-items: center;
  gap: 12px;
  width: 100%;
}

.member-picker__selected {
  margin-right: auto;
  color: var(--color-text-dim);
}
</style>
