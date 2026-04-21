<script lang="ts">
export default {
  name: "HangarGroupLabels",
};
</script>

<script lang="ts" setup>
import Sortable from "sortablejs";
import BtnDropdown from "@/shared/components/base/BtnDropdown/index.vue";
import Btn from "@/shared/components/base/Btn/index.vue";
import { BtnSizesEnum } from "@/shared/components/base/Btn/types";
import { useI18n } from "@/shared/composables/useI18n";
import { useMobile } from "@/shared/composables/useMobile";
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
  editable?: boolean;
};

const props = withDefaults(defineProps<Props>(), {
  hangarGroups: () => [],
  hangarGroupCounts: () => [],
  editable: false,
});

const { t } = useI18n();

const mobile = useMobile();

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

const isActive = (group: string) => {
  return toArray(filters.value.hangarGroupsIn).includes(group);
};

const isInverted = (group: string) => {
  return toArray(filters.value.hangarGroupsNotIn).includes(group);
};

const groups = ref<(HangarGroup | HangarGroupPublic)[]>([]);

const { displayAlert } = useAppNotifications();

const sortMutation = useHangarGroupSortMutation();

const sortableContainer = ref<HTMLElement | null>(null);
let sortableInstance: Sortable | null = null;

const initSortable = () => {
  if (sortableInstance) {
    sortableInstance.destroy();
  }

  if (!sortableContainer.value) return;

  sortableInstance = Sortable.create(sortableContainer.value, {
    animation: 150,
    onEnd: async () => {
      const items = sortableContainer.value?.querySelectorAll("[data-group-id]");
      if (!items) return;

      const newOrder = Array.from(items).map((el) =>
        el.getAttribute("data-group-id"),
      );
      groups.value = newOrder
        .map((id) => groups.value.find((g) => g.id === id))
        .filter(Boolean) as (HangarGroup | HangarGroupPublic)[];

      await updateSort();
    },
  });
};

onMounted(() => {
  groups.value = props.hangarGroups;
  nextTick(() => initSortable());
});

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

const emit = defineEmits(["highlight"]);

const highlight = (group?: HangarGroup | HangarGroupPublic) => {
  emit("highlight", group);
};
</script>

<template>
  <BtnDropdown
    v-if="mobile"
    :mobile-block="true"
    :size="BtnSizesEnum.SMALL"
    class="labels-dropdown"
  >
    <template #label>
      {{ t("labels.groups") }}
    </template>
    <Btn
      v-for="group in groups"
      :key="group.id"
      class="labels-dropdown-item"
      :class="{
        active: isActive(group.slug),
        inverted: isInverted(group.slug),
      }"
      @click="filterGroup(group.slug)"
    >
      <span
        :style="{
          'background-color': group.color,
        }"
        class="label-color"
      />
      <span class="label-text-wrapper">
        <span class="label-text">
          {{ group.name }}
        </span>
        <span class="label-count">{{ groupCount(group).count }}</span>
      </span>
    </Btn>
    <Btn
      v-if="editable"
      class="labels-dropdown-item"
      @click="openNewGroupModal"
    >
      <i class="fa-regular fa-plus" />
      <span class="label-text-wrapper">
        <span class="label-text">
          {{ t("actions.addGroup") }}
        </span>
      </span>
    </Btn>
  </BtnDropdown>
  <div v-else class="labels">
    <h3 v-if="groups.length || editable" class="label-title">
      {{ t("labels.groups") }}:
    </h3>
    <div ref="sortableContainer" class="labels-sortable">
      <a
        v-for="group in groups"
        :key="group.id"
        :data-group-id="group.id"
        :class="{
          active: isActive(group.slug),
          inverted: isInverted(group.slug),
        }"
        class="label label-link fade-list-item"
        @click.exact="filterGroup(group.slug)"
        @click.right.prevent="openGroupModal(group)"
        @mouseenter="highlight(group)"
        @mouseleave="highlight()"
      >
        <span class="label-inner">
          <span
            :style="{
              'background-color': group.color,
            }"
            class="label-color"
          />
          {{ group.name }}: {{ groupCount(group).count }}
        </span>
      </a>
    </div>
    <a
      v-if="editable"
      v-tooltip="t('actions.addGroup')"
      :aria-label="t('actions.addGroup')"
      class="label label-link"
      @click="openNewGroupModal"
    >
      <span class="label-inner">
        <i class="fa-regular fa-plus" />
      </span>
    </a>
  </div>
</template>

<style lang="scss" scoped>
@import "index";
</style>
