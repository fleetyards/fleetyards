<script lang="ts">
export default {
  name: "VisualTestsListsPage",
};
</script>

<script lang="ts" setup>
import Btn from "@/shared/components/base/Btn/index.vue";
import BasePill from "@/shared/components/base/Pill/index.vue";
import FilterGroup from "@/shared/components/base/FilterGroup/index.vue";
import FormInput from "@/shared/components/base/FormInput/index.vue";
import InlineEditableList from "@/shared/components/InlineEditableList/index.vue";
import ListGroup from "@/shared/components/ListGroup/index.vue";
import FilteredList from "@/shared/components/FilteredList/index.vue";
import { BtnSizesEnum } from "@/shared/components/base/Btn/types";
import { HeadingLevelEnum } from "@/shared/components/base/Heading/types";
import { type AsyncStatus } from "@/shared/components/AsyncData.types";
import { type FilterOption } from "@/services/fyApi";
import { useAppNotifications } from "@/shared/composables/useAppNotifications";
import { v4 as uuidv4 } from "uuid";

const { displaySuccess, dismissConfirm } = useAppNotifications();

type Dock = {
  id: string;
  name: string;
  dockType: string;
  shipSize: string;
};

const dockTypeOptions: FilterOption[] = [
  { label: "Vehicle Pad", value: "vehiclepad" },
  { label: "Garage", value: "garage" },
  { label: "Landing Pad", value: "landingpad" },
  { label: "Docking Port", value: "dockingport" },
  { label: "Hangar", value: "hangar" },
];

const shipSizeOptions: FilterOption[] = [
  { label: "Small", value: "small" },
  { label: "Medium", value: "medium" },
  { label: "Large", value: "large" },
  { label: "Capital", value: "capital" },
];

const optionLabel = (options: FilterOption[], value: string) =>
  options.find((option) => option.value === value)?.label || value;

const buildDocks = (): Dock[] => [
  {
    id: "dock-1",
    name: "Forward Bay",
    dockType: "hangar",
    shipSize: "large",
  },
  {
    id: "dock-2",
    name: "Port Pad",
    dockType: "landingpad",
    shipSize: "medium",
  },
  {
    id: "dock-3",
    name: "Starboard Pad",
    dockType: "landingpad",
    shipSize: "medium",
  },
  {
    id: "dock-4",
    name: "Rover Garage",
    dockType: "garage",
    shipSize: "small",
  },
];

// ── ListGroup ────────────────────────────────────────────────────────

const listGroupItems = ref(buildDocks());

// ── InlineEditableList | full ────────────────────────────────────────

type EditableListRef = {
  editingId: string | null;
  creating: boolean;
  selected: string[];
  startCreate: () => void;
  finishEdit: () => void;
  finishCreate: () => void;
  resetSelected: () => void;
} | null;

const editableList = ref<EditableListRef>(null);

const docks = ref(buildDocks());

const editForm = ref<Partial<Dock>>({});

const onStartEdit = (item: Dock) => {
  editForm.value = {
    name: item.name,
    dockType: item.dockType,
    shipSize: item.shipSize,
  };
};

const onSaveEdit = () => {
  const id = editableList.value?.editingId;

  if (!id) {
    return;
  }

  docks.value = docks.value.map((item) =>
    item.id === id ? { ...item, ...editForm.value } : item,
  );

  editableList.value?.finishEdit();
};

const createForm = ref<Partial<Dock>>({});

const onStartCreate = () => {
  createForm.value = {
    name: "",
    dockType: "landingpad",
    shipSize: "medium",
  };
};

const onSaveCreate = () => {
  docks.value = [
    ...docks.value,
    {
      id: uuidv4(),
      name: createForm.value.name || "Unnamed Dock",
      dockType: createForm.value.dockType || "landingpad",
      shipSize: createForm.value.shipSize || "medium",
    },
  ];

  editableList.value?.finishCreate();
};

const expandedId = ref<string | null>(null);

const toggleExpanded = (id: string) => {
  expandedId.value = expandedId.value === id ? null : id;
};

// Selection deliberately survives `items` changing, so that select-all can span
// pages — which means removing a record does not deselect it. The owner of the
// records has to prune the id, or bulk actions keep counting a row nobody sees.
const onDestroy = (item: Dock) => {
  docks.value = docks.value.filter((entry) => entry.id !== item.id);

  if (editableList.value) {
    editableList.value.selected = editableList.value.selected.filter(
      (id) => id !== item.id,
    );
  }

  if (expandedId.value === item.id) {
    expandedId.value = null;
  }
};

const bulkCopy = (selected: string[]) => {
  displaySuccess({ text: `Copied ${selected.length} docks.` });
};

// A pending destroy confirmation captured the item it was opened for, and
// `buildDocks` hands back the same ids, so confirming after a reset would delete
// a record from the freshly restored list.
const resetDocks = () => {
  dismissConfirm();
  docks.value = buildDocks();
  editableList.value?.finishEdit();
  editableList.value?.finishCreate();
  editableList.value?.resetSelected();
  expandedId.value = null;
};

// ── InlineEditableList | actions-only ────────────────────────────────

const readOnlyDocks = ref(buildDocks());

// ── FilteredList ─────────────────────────────────────────────────────

const filteredListLoading = ref(false);
const filteredListRefetching = ref(false);
const filteredListError = ref(false);
const filteredListRecords = ref(buildDocks());
const filteredListSize = ref<string | null>(null);

const asyncStatus: AsyncStatus = {
  fetchStatus: computed(() =>
    filteredListLoading.value ? "fetching" : "idle",
  ),
  isError: computed(() => filteredListError.value),
  isPending: computed(() => filteredListLoading.value),
  isLoading: computed(() => filteredListLoading.value),
  isFetching: computed(
    () => filteredListLoading.value || filteredListRefetching.value,
  ),
  isRefetching: computed(() => filteredListRefetching.value),
  error: computed(() =>
    filteredListError.value ? new Error("Simulated request failure") : null,
  ),
};

const toggleFilteredListLoading = () => {
  filteredListLoading.value = !filteredListLoading.value;
};

const toggleFilteredListRefetching = () => {
  filteredListRefetching.value = !filteredListRefetching.value;
};

const toggleFilteredListError = () => {
  filteredListError.value = !filteredListError.value;
};

const toggleFilteredListEmpty = () => {
  filteredListRecords.value = filteredListRecords.value.length
    ? []
    : buildDocks();
};
</script>

<template>
  <Heading :level="HeadingLevelEnum.H2">ListGroup</Heading>
  <p>
    The plain list container behind the editable list — rows with a display and
    an actions area, plus its own loading and empty states.
  </p>
  <div class="row">
    <div class="col-12 col-xl-6">
      <ListGroup :items="listGroupItems" empty-name="Docks">
        <template #display="{ item }">
          <BasePill uppercase margin-right>
            {{ optionLabel(dockTypeOptions, item.dockType) }}
          </BasePill>
          <span>{{ item.name }}</span>
        </template>
        <template #actions="{ item }">
          <Btn
            :size="BtnSizesEnum.SMALL"
            inline
            @click="displaySuccess({ text: `Picked ${item.name}` })"
          >
            <i class="fa-duotone fa-arrow-right" />
          </Btn>
        </template>
      </ListGroup>
    </div>
    <div class="col-12 col-xl-6">
      <ListGroup :items="[]" empty-name="Docks" loading />
      <ListGroup :items="[]" empty-name="Docks" />
    </div>
  </div>

  <Heading :level="HeadingLevelEnum.H2">InlineEditableList</Heading>
  <p>
    Fully wired against local state — create, edit and destroy all mutate the
    list in place. Rows are selectable, and the expand toggle opens the
    <code>expanded</code> slot.
  </p>
  <div class="flex items-center justify-between">
    <div>
      <Btn
        :size="BtnSizesEnum.SMALL"
        :disabled="editableList?.creating"
        data-test="start-create"
        @click="editableList?.startCreate()"
      >
        <i class="fa-duotone fa-plus" />
        Add
      </Btn>
      <Btn
        :size="BtnSizesEnum.SMALL"
        data-test="reset-docks"
        @click="resetDocks"
      >
        <i class="fa-duotone fa-rotate-left" />
        Reset
      </Btn>
    </div>
  </div>

  <InlineEditableList
    ref="editableList"
    empty-name="Docks"
    selectable
    :items="docks"
    confirm-destroy-text="Really destroy this dock?"
    @start-edit="onStartEdit"
    @save-edit="onSaveEdit"
    @start-create="onStartCreate"
    @save-create="onSaveCreate"
    @destroy="onDestroy"
  >
    <template #selected-actions="{ selected }">
      <Btn :size="BtnSizesEnum.SMALL" @click="bulkCopy(selected)">
        <i class="fa-duotone fa-copy" />
        Copy
      </Btn>
    </template>

    <template #display="{ item }">
      <BasePill uppercase margin-right>
        {{ optionLabel(dockTypeOptions, item.dockType) }}
      </BasePill>
      <BasePill margin-right>
        {{ optionLabel(shipSizeOptions, item.shipSize) }}
      </BasePill>
      <span>{{ item.name }}</span>
    </template>

    <template #edit>
      <FilterGroup
        v-model="editForm.dockType"
        name="edit-dock-type"
        :options="dockTypeOptions"
        :nullable="false"
        label="Dock Type"
      />
      <FilterGroup
        v-model="editForm.shipSize"
        name="edit-ship-size"
        :options="shipSizeOptions"
        :nullable="false"
        label="Ship Size"
      />
      <FormInput v-model="editForm.name" name="edit-name" label="Name" />
    </template>

    <template #create>
      <FilterGroup
        v-model="createForm.dockType"
        name="create-dock-type"
        :options="dockTypeOptions"
        :nullable="false"
        label="Dock Type"
      />
      <FilterGroup
        v-model="createForm.shipSize"
        name="create-ship-size"
        :options="shipSizeOptions"
        :nullable="false"
        label="Ship Size"
      />
      <FormInput v-model="createForm.name" name="create-name" label="Name" />
    </template>

    <template #actions="{ item, mobile }">
      <Btn
        :size="BtnSizesEnum.SMALL"
        :class="expandedId === item.id ? 'text-primary' : ''"
        data-test="toggle-expanded"
        @click="toggleExpanded(item.id)"
      >
        <i class="fa-duotone fa-chevron-down" />
        <span v-if="mobile">Details</span>
      </Btn>
    </template>

    <template #expanded="{ item }">
      <div v-if="expandedId === item.id" class="visual-tests-lists__expanded">
        The <code>expanded</code> slot for <strong>{{ item.name }}</strong> —
        rendered below the row, full width.
      </div>
    </template>
  </InlineEditableList>

  <Heading :level="HeadingLevelEnum.H2">
    InlineEditableList | Custom Actions Only
  </Heading>
  <p>
    With <code>hide-edit</code> and <code>hide-destroy</code> the built-in
    buttons drop out and the <code>actions</code> slot renders bare — no button
    group, no mobile dropdown.
  </p>
  <InlineEditableList
    empty-name="Docks"
    hide-edit
    hide-destroy
    :items="readOnlyDocks"
  >
    <template #display="{ item }">
      <span>{{ item.name }}</span>
    </template>
    <template #actions="{ item }">
      <Btn
        :size="BtnSizesEnum.SMALL"
        inline
        @click="displaySuccess({ text: `Pinned ${item.name}` })"
      >
        <i class="fa-duotone fa-thumbtack" />
      </Btn>
    </template>
  </InlineEditableList>

  <Heading :level="HeadingLevelEnum.H2">
    InlineEditableList | Loading & Empty
  </Heading>
  <p>Both states are delegated to the underlying ListGroup.</p>
  <div class="row">
    <div class="col-12 col-xl-6">
      <InlineEditableList :items="[]" empty-name="Docks" loading />
    </div>
    <div class="col-12 col-xl-6">
      <InlineEditableList :items="[]" empty-name="Docks" />
    </div>
  </div>

  <Heading :level="HeadingLevelEnum.H2">FilteredList</Heading>
  <p>
    The list shell used by the ships, hangar and fleet pages — filter drawer,
    action bars and the loading / empty / error states it derives from the query
    status.
  </p>
  <div class="row">
    <div class="col-12">
      <Btn
        :size="BtnSizesEnum.SMALL"
        :active="filteredListLoading"
        data-test="toggle-filtered-list-loading"
        @click="toggleFilteredListLoading"
      >
        Loading
      </Btn>
      <Btn
        :size="BtnSizesEnum.SMALL"
        :active="filteredListRefetching"
        data-test="toggle-filtered-list-refetching"
        @click="toggleFilteredListRefetching"
      >
        Refetching
      </Btn>
      <Btn
        :size="BtnSizesEnum.SMALL"
        :active="!filteredListRecords.length"
        data-test="toggle-filtered-list-empty"
        @click="toggleFilteredListEmpty"
      >
        Empty
      </Btn>
      <Btn
        :size="BtnSizesEnum.SMALL"
        :active="filteredListError"
        data-test="toggle-filtered-list-error"
        @click="toggleFilteredListError"
      >
        Error
      </Btn>
    </div>
  </div>

  <FilteredList
    name="visual-tests-docks"
    :records="filteredListRecords"
    :async-status="asyncStatus"
    :is-filter-selected="!!filteredListSize"
  >
    <template #actions-left>
      <Btn :size="BtnSizesEnum.SMALL">
        <i class="fa-duotone fa-plus" />
      </Btn>
    </template>
    <template #actions-right="{ records }">
      <span class="text-muted">{{ records.length }} docks</span>
    </template>
    <template #filter>
      <FilterGroup
        v-model="filteredListSize"
        name="filtered-list-ship-size"
        :options="shipSizeOptions"
        label="Ship Size"
      />
    </template>
    <template #default="{ records }">
      <ListGroup :items="records" empty-name="Docks">
        <template #display="{ item }">
          <BasePill uppercase margin-right>
            {{ optionLabel(shipSizeOptions, item.shipSize) }}
          </BasePill>
          <span>{{ item.name }}</span>
        </template>
      </ListGroup>
    </template>
  </FilteredList>
</template>

<style lang="scss" scoped>
.visual-tests-lists__expanded {
  padding: 12px 16px;
  color: $gray-light;
}
</style>
