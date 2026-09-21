<script lang="ts">
export default {
  name: "FleetSquadronMemberPicker",
};
</script>

<script lang="ts" setup>
import Modal from "@/shared/components/AppModal/Inner/index.vue";
import Btn from "@/shared/components/base/Btn/index.vue";
import { BtnSizesEnum } from "@/shared/components/base/Btn/types";
import FormInput from "@/shared/components/base/FormInput/index.vue";
import Avatar from "@/shared/components/Avatar/index.vue";
import Empty from "@/shared/components/Empty/index.vue";
import Loader from "@/shared/components/Loader/index.vue";
import { useI18n } from "@/shared/composables/useI18n";
import { useAppNotifications } from "@/shared/composables/useAppNotifications";
import { useComlink } from "@/shared/composables/useComlink";
import { refDebounced } from "@vueuse/core";
import {
  type Fleet,
  type FleetSquadron,
  type FleetMember,
  type FleetMembersParams,
  useFleetMembers,
  useCreateFleetSquadronMember,
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

const selected = ref<string[]>([]);
const submitting = ref(false);

const queryParams = computed<FleetMembersParams>(() => ({
  perPage: "50",
  q: {
    usernameCont: debouncedSearch.value || undefined,
    stateIn: ["accepted"],
  },
}));

const { data: members, isLoading } = useFleetMembers(
  props.fleet.slug,
  queryParams,
);

// Filtered here rather than in the query: no endpoint answers "not in this
// squadron", and a fleet's roster is small enough that asking for the page and
// dropping the ones already in is cheaper than adding one.
const candidates = computed<FleetMember[]>(() =>
  (members.value?.items ?? []).filter(
    (member) =>
      !(member.squadrons ?? []).some(
        (squadron) => squadron.id === props.squadron.id,
      ),
  ),
);

const toggle = (username: string) => {
  const index = selected.value.indexOf(username);

  if (index === -1) {
    selected.value.push(username);
  } else {
    selected.value.splice(index, 1);
  }
};

const mutation = useCreateFleetSquadronMember();

// One request per person, and a failure part-way through leaves the ones
// already added in place: they are separate rows, and undoing them would be a
// second way to remove somebody that nobody asked for. The message says how
// many landed.
const onSubmit = async () => {
  if (!selected.value.length) return;

  submitting.value = true;

  const results = await Promise.allSettled(
    selected.value.map((username) =>
      mutation.mutateAsync({
        fleetSlug: props.fleet.slug,
        fleetSquadronSlug: props.squadron.slug,
        data: { username },
      }),
    ),
  );

  submitting.value = false;

  const added = results.filter(
    (result) => result.status === "fulfilled",
  ).length;
  const failed = results.length - added;

  if (added) {
    comlink.emit("fleet-squadron-members-updated");
    displaySuccess({
      text: t("messages.fleet.squadrons.members.add.success", { count: added }),
    });
  }

  if (failed) {
    displayAlert({
      text: t("messages.fleet.squadrons.members.add.failure", {
        count: failed,
      }),
    });
    return;
  }

  comlink.emit("close-modal");
};
</script>

<template>
  <Modal :title="t('headlines.fleets.squadrons.addMembers')">
    <FormInput
      v-model="search"
      name="squadron-member-search"
      :no-label="true"
      :clearable="true"
      :label="t('labels.fleet.squadrons.searchMembers')"
    />

    <Loader :loading="isLoading" />

    <ul v-if="candidates.length" class="squadron-member-picker">
      <li v-for="member in candidates" :key="member.id">
        <button
          type="button"
          class="squadron-member-row"
          :class="{ selected: selected.includes(member.username) }"
          :data-test="`squadron-member-option-${member.username}`"
          @click="toggle(member.username)"
        >
          <Avatar :avatar="member.avatar?.smallUrl" size="small" />
          <span class="squadron-member-name">{{ member.username }}</span>
          <i
            class="fa-solid"
            :class="
              selected.includes(member.username)
                ? 'fa-check-square'
                : 'fa-square'
            "
          />
        </button>
      </li>
    </ul>

    <Empty
      v-else-if="!isLoading"
      :name="t('labels.fleet.squadrons.availableMembers')"
      inline
    />

    <template #footer>
      <div class="modal-actions">
        <Btn
          :loading="submitting"
          :disabled="!selected.length"
          :size="BtnSizesEnum.LG"
          data-test="squadron-add-members"
          @click="onSubmit"
        >
          {{
            t("actions.fleet.squadrons.addMembers", { count: selected.length })
          }}
        </Btn>
      </div>
    </template>
  </Modal>
</template>

<style lang="scss" scoped>
.squadron-member-picker {
  display: flex;
  flex-direction: column;
  gap: 4px;
  margin: 0;
  padding: 0;
  list-style: none;
  max-height: 50vh;
  overflow-y: auto;
}

.squadron-member-row {
  display: flex;
  align-items: center;
  gap: 10px;
  width: 100%;
  padding: 8px 10px;
  background: none;
  border: 1px solid transparent;
  color: var(--color-text-dim);
  cursor: pointer;
  text-align: left;

  &:hover {
    color: var(--color-text);
    border-color: var(--color-border);
  }

  &.selected {
    color: var(--color-text);
    border-color: var(--color-primary);
  }
}

.squadron-member-name {
  flex: 1;
  min-width: 0;
}
</style>
