<script lang="ts">
export default {
  name: "HangarGroupLabels",
};
</script>

<script lang="ts" setup>
import Sortable from "sortablejs";
import Btn from "@/shared/components/base/Btn/index.vue";
import { BtnSizesEnum } from "@/shared/components/base/Btn/types";
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

watch(
  () => props.hangarGroups,
  (newGroups) => {
    groups.value = newGroups;
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

const row = ref<{ itemsEl: HTMLElement | null } | null>(null);
let sortableInstance: Sortable | null = null;

const initSortable = (container?: HTMLElement | null) => {
  if (sortableInstance) {
    sortableInstance.destroy();
    sortableInstance = null;
  }

  if (!container) return;

  sortableInstance = Sortable.create(container, {
    animation: 150,
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
});

// Bound to the element, not to mount: the row swaps its desktop branch for a
// dropdown at the mobile breakpoint, so the container Sortable was given can be
// replaced or removed under it. Watching re-binds on the way back to desktop and
// releases the detached one on the way out - the previous version bound once in
// onMounted and left dragging silently unavailable after a resize.
watch(
  () => row.value?.itemsEl,
  (container) => initSortable(container),
  { immediate: true, flush: "post" },
);

onUnmounted(() => {
  sortableInstance?.destroy();
});

const updateSort = async () => {
  const sorting = groups.value.map((item) => item.id);
  await sortMutation
    .mutateAsync({
      data: { sorting },
    })
    .catch((error) => {
      displayAlert({
        text: error.response?.data?.message,
      });
    });
};

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
  <ChipRow ref="row" :label="label ?? t('labels.groups')">
    <Chip
      v-for="group in groups"
      :key="group.id"
      :data-group-id="group.id"
      :state="groupState(group.slug)"
      :dot="group.color"
      :count="groupCount(group).count"
      :editable="editable"
      :edit-label="t('actions.editGroup')"
      @toggle="filterGroup(group.slug)"
      @edit="openGroupModal(group)"
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
    </template>

    <!-- The mobile items go through Btn's own `active` prop. The stylesheet this
         replaces reached at Btn's internals with six !important declarations -
         the override class btn-redesign swept out of 17 files. -->
    <template #menu>
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
      <Btn v-if="editable" @click="openNewGroupModal">
        <i class="fa-regular fa-plus" />
        {{ t("actions.addGroup") }}
      </Btn>
    </template>
  </ChipRow>
</template>
