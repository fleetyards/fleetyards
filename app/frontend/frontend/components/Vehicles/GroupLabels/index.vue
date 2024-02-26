<template>
  <BtnDropdown
    v-if="mobile"
    :mobile-block="true"
    size="small"
    class="labels-dropdown"
  >
    <template #label>
      {{ t("labels.groups") }}
    </template>
    <Btn
      v-for="group in groups"
      :key="group.id"
      variant="dropdown"
      class="labels-dropdown-item"
      :class="{
        active: isActive(group.slug),
        inverted: isInverted(group.slug),
      }"
      @click.exact="filter(group.slug)"
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
          @click.exact="filter(group.slug)"
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
      @click="openGroupModal"
    >
      <span class="label-inner">
        <i class="far fa-plus" />
      </span>
    </a>
  </div>
</template>

<script lang="ts" setup>
import draggable from "vuedraggable";
import BtnDropdown from "@/shared/components/base/BtnDropdown/index.vue";
import Btn from "@/shared/components/base/Btn/index.vue";
import { useI18n } from "@/frontend/composables/useI18n";
import { useNoty } from "@/shared/composables/useNoty";
import { useMobile } from "@/shared/composables/useMobile";
import type { HangarGroup, HangarGroupMetric } from "@/services/fyApi";
import { useComlink } from "@/shared/composables/useComlink";

type Props = {
  hangarGroups: HangarGroup[];
  hangarGroupCounts: HangarGroupMetric[];
  editable: boolean;
};

const props = withDefaults(defineProps<Props>(), {
  hangarGroups: () => [],
  hangarGroupCounts: () => [],
  editable: false,
});

const { t } = useI18n();

const { displayAlert } = useNoty(t);

const drag = ref(false);

const groups = ref<HangarGroup[]>([]);

const mobile = useMobile();

const sortIndex = computed(() => {
  return groups.value.map((item) => item.id);
});

onMounted(() => {
  groups.value = props.hangarGroups;
});

watch(
  () => props.hangarGroups,
  () => {
    groups.value = props.hangarGroups;
  },
);

watch(
  () => groups.value,
  () => {
    if (groups.value !== props.hangarGroups) {
      updateSort();
    }
  },
);

const groupCount = (group: HangarGroup) => {
  return (
    props.hangarGroupCounts.find((count) => count.id === group.id) || {
      count: 0,
    }
  );
};

const route = useRoute();

const router = useRouter();

const filter = (filter) => {
  const query = JSON.parse(JSON.stringify(route.query.q || {}));

  if ((query.hangarGroupsIn || []).includes(filter)) {
    if (!query.hangarGroupsNotIn) {
      query.hangarGroupsNotIn = [];
    }
    query.hangarGroupsNotIn.push(filter);

    const index = query.hangarGroupsIn.findIndex((item) => item === filter);
    if (index > -1) {
      query.hangarGroupsIn.splice(index, 1);
    }
  } else if ((query.hangarGroupsNotIn || []).includes(filter)) {
    const index = query.hangarGroupsNotIn.findIndex((item) => item === filter);
    if (index > -1) {
      query.hangarGroupsNotIn.splice(index, 1);
    }
  } else {
    if (!query.hangarGroupsIn) {
      query.hangarGroupsIn = [];
    }
    query.hangarGroupsIn.push(filter);
  }

  router.replace({
    name: route.name,
    query: {
      q: query,
    },
  });
};

const isActive = (group: string) => {
  if (!route.query.q) {
    return false;
  }

  const filter = route.query.q.hangarGroupsIn;
  if (!filter) {
    return false;
  }

  if (filter.includes(group)) {
    return true;
  }

  return false;
};

const isInverted = (group: string) => {
  if (!route.query.q) {
    return false;
  }

  const filter = route.query.q.hangarGroupsNotIn;
  if (!filter) {
    return false;
  }

  if (filter.includes(group)) {
    return true;
  }

  return false;
};

const updateSort = async () => {
  const response = await this.$api.put("hangar-groups/sort", {
    sorting: sortIndex.value,
  });

  if (response.error) {
    displayAlert({
      text: response.error.response.data.message,
    });
  }
};

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

const emit = defineEmits(["highlight"]);

const highlight = (group?: HangarGroup) => {
  emit("highlight", group);
};
</script>

<script lang="ts">
export default {
  name: "GroupLabels",
};
</script>

<style lang="scss" scoped>
@import "index";
</style>
