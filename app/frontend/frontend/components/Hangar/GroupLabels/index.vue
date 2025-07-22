<script lang="ts">
export default {
  name: "HangarGroupLabels",
};
</script>

<script lang="ts" setup>
import draggable from "vuedraggable";
import BtnDropdown from "@/shared/components/base/BtnDropdown/index.vue";
import Btn from "@/shared/components/base/Btn/index.vue";
import { BtnSizesEnum } from "@/shared/components/base/Btn/types";
import { useI18n } from "@/shared/composables/useI18n";
import { useAppNotifications } from "@/shared/composables/useAppNotifications";
import { useMobile } from "@/shared/composables/useMobile";
import { useComlink } from "@/shared/composables/useComlink";
import {
  useHangarGroupSort as useHangarGroupSortMutation,
  type HangarQuery,
  type HangarGroup,
  type HangarGroupPublic,
  type HangarGroupMetric,
} from "@/services/fyApi";
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

onMounted(() => {
  groups.value = props.hangarGroups;
});

watch(
  () => props.hangarGroups,
  () => {
    groups.value = props.hangarGroups;
  },
);

const { filter, filters } = useHangarFilters();

const groupCount = (group: HangarGroup) => {
  return (
    props.hangarGroupCounts.find((count) => count.id === group.id) || {
      count: 0,
    }
  );
};

const route = useRoute();

const filterGroup = (group: string) => {
  const hangarGroupsIn = filters.value.hangarGroupsIn;
  const hangarGroupsNotIn = filters.value.hangarGroupsNotIn;

  if (!hangarGroupsIn && !hangarGroupsNotIn) {
    filter({
      hangarGroupsIn: [group],
    });
  } else if (hangarGroupsIn && hangarGroupsIn.includes(group)) {
    filter({
      hangarGroupsIn: hangarGroupsIn.filter((g) => g !== group),
      hangarGroupsNotIn: [...(hangarGroupsNotIn || []), group],
    });
  } else if (hangarGroupsIn && !hangarGroupsIn.includes(group)) {
    filter({
      hangarGroupsIn: [...(hangarGroupsIn || []), group],
    });
  } else if (hangarGroupsNotIn && hangarGroupsNotIn.includes(group)) {
    filter({
      hangarGroupsNotIn: hangarGroupsNotIn.filter((g) => g !== group),
    });
  } else if (hangarGroupsNotIn && !hangarGroupsNotIn.includes(group)) {
    filter({
      hangarGroupsNotIn: [...(hangarGroupsNotIn || []), group],
    });
  }
};

const isActive = (group: string) => {
  const hangarGroupsIn = filters.value.hangarGroupsIn;

  if (!hangarGroupsIn) {
    return false;
  }

  if (hangarGroupsIn.includes(group)) {
    return true;
  }

  return false;
};

const isInverted = (group: string) => {
  const hangarGroupsNotIn = filters.value.hangarGroupsNotIn;

  if (!hangarGroupsNotIn) {
    return false;
  }

  if (hangarGroupsNotIn.includes(group)) {
    return true;
  }

  return false;
};

const drag = ref(false);

const groups = ref<HangarGroup[]>([]);

// watch(
//   () => groups.value,
//   () => {
//     if (groups.value !== props.hangarGroups) {
//       updateSort();
//     }
//   },
// );

// const sortIndex = computed(() => {
//   return groups.value.map((item) => item.id);
// });

// const sortMutation = useHangarGroupSortMutation();

// const { displayAlert } = useAppNotifications();

// const updateSort = async () => {
//   await sortMutation
//     .mutateAsync({
//       sorting: sortIndex.value,
//     })
//     .catch((error) => {
//       displayAlert({
//         text: error.response.data.message,
//       });
//     });
// };

const comlink = useComlink();

const openGroupModal = (hangarGroup?: HangarGroup) => {
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

const highlight = (group?: HangarGroup) => {
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
      @click.exact="filterGroup(group.slug)"
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
  </BtnDropdown>
  <div v-else class="labels">
    <h3 v-if="groups.length || editable" class="label-title">
      {{ t("labels.groups") }}:
    </h3>
    <draggable
      v-model="groups"
      group="hangarGroups"
      item-key="id"
      @start="drag = true"
      @end="drag = false"
    >
      <template #item="{ element: group }">
        <a
          :key="group.id"
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
      </template>
    </draggable>
    <a
      v-if="editable"
      v-tooltip="t('actions.addGroup')"
      class="label label-link"
      @click="openNewGroupModal"
    >
      <span class="label-inner">
        <i class="far fa-plus" />
      </span>
    </a>
  </div>
</template>

<style lang="scss" scoped>
@import "index";
</style>
