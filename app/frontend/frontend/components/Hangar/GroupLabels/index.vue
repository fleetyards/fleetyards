<script lang="ts">
export default {
  name: "HangarGroupLabels",
};
</script>

<script lang="ts" setup>
import Sortable from "sortablejs";
import Btn from "@/shared/components/base/Btn/index.vue";
import { BtnSizesEnum } from "@/shared/components/base/Btn/types";
import BtnGroup from "@/shared/components/base/BtnGroup/index.vue";
import Chip from "@/shared/components/base/Chip/index.vue";
import ChipRow from "@/shared/components/base/Chip/Row/index.vue";
import { ChipStatesEnum } from "@/shared/components/base/Chip/types";

import { useI18n } from "@/shared/composables/useI18n";
import { useComlink } from "@/shared/composables/useComlink";
import {
  type HangarGroup,
  type HangarGroupPublic,
  type HangarGroupMetric,
  useHangarGroupSort as useHangarGroupSortMutation,
} from "@/services/fyApi";
import { useAppNotifications } from "@/shared/composables/useAppNotifications";
import { useHangarFilters } from "@/frontend/composables/useHangarFilters";

type Props = {
  hangarGroups?: (HangarGroup | HangarGroupPublic)[];
  hangarGroupCounts?: HangarGroupMetric[];
  label?: string;
  editable?: boolean;
};

const props = withDefaults(defineProps<Props>(), {
  hangarGroups: () => [],
  hangarGroupCounts: () => [],
  label: undefined,
  editable: false,
});

const { t } = useI18n();

const groups = ref<(HangarGroup | HangarGroupPublic)[]>([]);

// One request at a time, and only the latest order once it settles: the server
// writes each request's full order, so overlapping requests from quick arrow
// presses could land out of order and persist an earlier one.
let sortRequest: Promise<void> | null = null;
let queuedSorting: string[] | null = null;
let lastSaveFailed = false;
// The order the server is known to hold: what it last returned, or what it last
// accepted since. A failed save falls back to this, not to the prop - after an
// earlier save in the same run succeeded, the prop predates it.
let savedOrder: string[] = [];

// Every group save broadcasts, so refetches arrive while a sort is still being
// saved, carrying an intermediate order. Their contents are taken - a rename or
// a group added in another tab - but in the order on screen, with new groups
// at the end.
const inOrder = (
  incoming: (HangarGroup | HangarGroupPublic)[],
  order: string[],
) => {
  const position = new Map(order.map((id, index) => [id, index]));

  return [...incoming].sort(
    (a, b) =>
      (position.get(a.id) ?? position.size) -
      (position.get(b.id) ?? position.size),
  );
};

watch(
  () => props.hangarGroups,
  (newGroups) => {
    if (sortRequest) {
      groups.value = inOrder(
        newGroups,
        groups.value.map((group) => group.id),
      );
      return;
    }

    groups.value = newGroups;
    savedOrder = newGroups.map((group) => group.id);
  },
);

const { filter, filters } = useHangarFilters();

const toArray = (value: string | string[] | undefined): string[] => {
  if (!value) return [];
  if (Array.isArray(value)) return value;
  return [value];
};

const groupCount = (group: HangarGroup | HangarGroupPublic) => {
  return (
    props.hangarGroupCounts.find((count) => count.id === group.id) || {
      count: 0,
    }
  );
};

const filterGroup = (group: string) => {
  const hangarGroupsIn = toArray(filters.value.hangarGroupsIn);
  const hangarGroupsNotIn = toArray(filters.value.hangarGroupsNotIn);

  if (!hangarGroupsIn.length && !hangarGroupsNotIn.length) {
    filter({
      hangarGroupsIn: [group],
    });
  } else if (hangarGroupsIn.includes(group)) {
    filter({
      hangarGroupsIn: hangarGroupsIn.filter((g) => g !== group),
      hangarGroupsNotIn: [...hangarGroupsNotIn, group],
    });
  } else if (hangarGroupsNotIn.includes(group)) {
    filter({
      hangarGroupsNotIn: hangarGroupsNotIn.filter((g) => g !== group),
    });
  } else {
    filter({
      hangarGroupsIn: [...hangarGroupsIn, group],
    });
  }
};

const groupState = (group: string) => {
  if (toArray(filters.value.hangarGroupsIn).includes(group)) {
    return ChipStatesEnum.INCLUDED;
  }

  if (toArray(filters.value.hangarGroupsNotIn).includes(group)) {
    return ChipStatesEnum.EXCLUDED;
  }

  return ChipStatesEnum.NEUTRAL;
};

const { displayAlert } = useAppNotifications();

const sortMutation = useHangarGroupSortMutation();

// Grips and edit actions only appear in edit mode, so a row at rest is plain
// filter chips with no slots reserved for controls that are not in use.
const editing = ref(false);

const toggleEditing = () => {
  editing.value = !editing.value;
};

const stopEditing = () => {
  editing.value = false;
};

const row = ref<{ itemsEl: HTMLElement | null } | null>(null);
let sortableInstance: Sortable | null = null;

const initSortable = (container?: HTMLElement | null) => {
  if (sortableInstance) {
    sortableInstance.destroy();
    sortableInstance = null;
  }

  if (!container || !props.editable || !editing.value) return;

  sortableInstance = Sortable.create(container, {
    animation: 150,
    handle: ".chip__handle",
    ghostClass: "chip--ghost",
    onEnd: () => {
      const items = container.querySelectorAll("[data-group-id]");
      if (!items) return;

      const newOrder = Array.from(items).map((el) =>
        el.getAttribute("data-group-id"),
      );
      groups.value = newOrder
        .map((id) => groups.value.find((g) => g.id === id))
        .filter(Boolean) as (HangarGroup | HangarGroupPublic)[];

      void updateSort();
    },
  });
};

onMounted(() => {
  groups.value = props.hangarGroups;
  savedOrder = props.hangarGroups.map((group) => group.id);
});

// Bound to the element, not to mount: the row swaps its desktop branch for a
// dropdown at the mobile breakpoint, so the container Sortable was given can be
// replaced or removed under it. Watching re-binds on the way back to desktop and
// releases the detached one on the way out - the previous version bound once in
// onMounted and left dragging silently unavailable after a resize.
watch(
  [() => row.value?.itemsEl, () => props.editable, editing],
  ([container]) => initSortable(container),
  { immediate: true, flush: "post" },
);

onUnmounted(() => {
  sortableInstance?.destroy();
});

const updateSort = () => {
  queuedSorting = groups.value.map((item) => item.id);

  if (sortRequest) return sortRequest;

  sortRequest = (async () => {
    while (queuedSorting) {
      const sorting = queuedSorting;
      queuedSorting = null;

      await sortMutation
        .mutateAsync({
          data: { sorting },
        })
        .then(() => {
          lastSaveFailed = false;
          savedOrder = sorting;
        })
        .catch((error) => {
          lastSaveFailed = true;
          displayAlert({
            text: error.response?.data?.message,
          });
        });
    }
  })().finally(() => {
    sortRequest = null;

    // Only the last request decides: a later success saved the full order an
    // earlier failure could not.
    if (lastSaveFailed) {
      lastSaveFailed = false;
      groups.value = inOrder(groups.value, savedOrder);
    }
  });

  return sortRequest;
};

// The keyboard and mobile counterpart to a drag. The control that moved it is
// refocused because Vue re-inserts the keyed element, and a re-inserted node
// drops its focus.
const moveGroup = async (
  group: HangarGroup | HangarGroupPublic,
  offset: -1 | 1,
  focusTarget: () => HTMLElement | null | undefined = () =>
    row.value?.itemsEl?.querySelector<HTMLElement>(
      `[data-group-id="${group.id}"] .chip__handle`,
    ),
) => {
  const from = groups.value.findIndex((item) => item.id === group.id);
  const to = from + offset;
  if (from < 0 || to < 0 || to >= groups.value.length) return;

  const reordered = [...groups.value];
  reordered.splice(to, 0, ...reordered.splice(from, 1));
  groups.value = reordered;

  void updateSort();

  await nextTick();
  focusTarget()?.focus();
};

// The menu is teleported to the body, so it is looked up in the document. At
// either end the arrow that was pressed is disabled, so the other one takes it.
const moveGroupInMenu = (
  group: HangarGroup | HangarGroupPublic,
  offset: -1 | 1,
) =>
  moveGroup(group, offset, () => {
    const menuRow = document.querySelector(
      `[data-group-menu-id="${group.id}"]`,
    );
    const pressed = offset < 0 ? "up" : "down";
    const other = offset < 0 ? "down" : "up";

    return (
      menuRow?.querySelector<HTMLElement>(
        `[data-test="group-menu-move-${pressed}"]:not([disabled])`,
      ) ??
      menuRow?.querySelector<HTMLElement>(
        `[data-test="group-menu-move-${other}"]`,
      )
    );
  });

const comlink = useComlink();

const openGroupModal = (hangarGroup?: HangarGroup | HangarGroupPublic) => {
  comlink.emit("open-modal", {
    component: () =>
      import("@/frontend/components/Vehicles/GroupModal/index.vue"),
    props: {
      hangarGroup,
    },
  });
};

const openNewGroupModal = () => {
  comlink.emit("open-modal", {
    component: () =>
      import("@/frontend/components/Vehicles/NewGroupModal/index.vue"),
  });
};

const emit = defineEmits<{
  highlight: [group?: HangarGroup | HangarGroupPublic];
}>();

const highlight = (group?: HangarGroup | HangarGroupPublic) => {
  emit("highlight", group);
};
</script>

<template>
  <ChipRow
    ref="row"
    :label="label ?? t('labels.groups')"
    :class="{ 'group-labels-editing': editing }"
    @keydown.esc="stopEditing"
  >
    <Chip
      v-for="group in groups"
      :key="group.id"
      :data-group-id="group.id"
      :state="groupState(group.slug)"
      :dot="group.color"
      :count="groupCount(group).count"
      :editable="editable && editing"
      :edit-label="t('actions.editGroup')"
      :sortable="editable && editing"
      :sort-label="t('actions.reorder')"
      @toggle="filterGroup(group.slug)"
      @edit="openGroupModal(group)"
      @move="moveGroup(group, $event)"
      @contextmenu.prevent="openGroupModal(group)"
      @mouseenter="highlight(group)"
      @mouseleave="highlight()"
    >
      {{ group.name }}
    </Chip>

    <template #actions>
      <Btn
        v-if="editable"
        v-tooltip="t('actions.addGroup')"
        :size="BtnSizesEnum.XS"
        :aria-label="t('actions.addGroup')"
        @click="openNewGroupModal"
      >
        <i class="fa-regular fa-plus" />
      </Btn>
      <Btn
        v-if="editable"
        v-tooltip="editing ? t('actions.done') : t('actions.edit')"
        :size="BtnSizesEnum.XS"
        :active="editing"
        :aria-label="editing ? t('actions.done') : t('actions.edit')"
        :aria-pressed="editing"
        class="group-labels-edit"
        data-test="group-labels-edit"
        @click="toggleEditing"
      >
        <i :class="editing ? 'fa-regular fa-check' : 'fa-regular fa-pen'" />
      </Btn>
    </template>

    <!-- The mobile items go through Btn's own `active` prop. The stylesheet this
         replaces reached at Btn's internals with six !important declarations -
         the override class btn-redesign swept out of 17 files. -->
    <template #menu>
      <template v-if="editable && editing">
        <!-- Arrows rather than a drag: a touch drag inside a dropdown fights its
             scrolling and its outside-tap close. The arrows and the edit mode
             toggle stop their click, which would otherwise close the menu. -->
        <div
          v-for="(group, index) in groups"
          :key="`menu-edit-${group.id}`"
          :data-group-menu-id="group.id"
          class="group-labels-menu-row"
          data-test="group-menu-row"
        >
          <Chip bare :dot="group.color" class="group-labels-menu-name">
            {{ group.name }}
          </Chip>
          <BtnGroup :size="BtnSizesEnum.SM">
            <Btn
              :aria-label="t('actions.moveUp')"
              :disabled="index === 0"
              data-test="group-menu-move-up"
              @click.stop="moveGroupInMenu(group, -1)"
            >
              <i class="fa-regular fa-arrow-up" />
            </Btn>
            <Btn
              :aria-label="t('actions.moveDown')"
              :disabled="index === groups.length - 1"
              data-test="group-menu-move-down"
              @click.stop="moveGroupInMenu(group, 1)"
            >
              <i class="fa-regular fa-arrow-down" />
            </Btn>
            <Btn
              :aria-label="t('actions.editGroup')"
              data-test="group-menu-edit"
              @click="openGroupModal(group)"
            >
              <i class="fa-regular fa-pen" />
            </Btn>
          </BtnGroup>
        </div>
      </template>
      <template v-else>
        <Btn
          v-for="group in groups"
          :key="`menu-${group.id}`"
          :active="groupState(group.slug) === ChipStatesEnum.INCLUDED"
          @click="filterGroup(group.slug)"
        >
          <Chip
            bare
            :state="groupState(group.slug)"
            :dot="group.color"
            :count="groupCount(group).count"
          >
            {{ group.name }}
          </Chip>
        </Btn>
      </template>
      <template v-if="editable">
        <hr />
        <Btn @click="openNewGroupModal">
          <i class="fa-regular fa-plus" />
          {{ t("actions.addGroup") }}
        </Btn>
        <Btn data-test="group-menu-edit-toggle" @click.stop="toggleEditing">
          <i :class="editing ? 'fa-regular fa-check' : 'fa-regular fa-pen'" />
          {{ editing ? t("actions.done") : t("actions.edit") }}
        </Btn>
      </template>
    </template>
  </ChipRow>
</template>

<style lang="scss" scoped>
/*
 * Revealed with the row rather than always shown: the row is a filter first, and
 * a permanent pen beside it reads as a control on every chip. Only where hover
 * exists - a touch screen at desktop width would otherwise never find it.
 * Keyboard focus reveals it too, but not :focus-within: a clicked chip keeps
 * focus, which held the button on screen after the pointer had left the row.
 */
@media (hover: hover) {
  .group-labels-edit {
    opacity: 0;
    transition: opacity 150ms ease-in-out;
  }

  .chip-row:hover,
  .chip-row:has(:focus-visible),
  .group-labels-editing {
    .group-labels-edit {
      opacity: 1;
    }
  }
}

// A menu row of its own rather than a menu item: it holds three controls, and
// a Btn in the menu goes full width. Padding matches a menu item's.
.group-labels-menu-row {
  display: flex;
  align-items: center;
  gap: 12px;
  padding: 6px 8px 6px 16px;
}

.group-labels-menu-name {
  flex: 1;
  min-width: 0;
}

@media (prefers-reduced-motion: reduce) {
  .group-labels-edit {
    transition-duration: 1ms;
  }
}
</style>
