<script lang="ts">
export default {
  name: "RoadmapPage",
};
</script>

<script lang="ts" setup>
import Btn from "@/shared/components/base/Btn/index.vue";
import BtnDropdown from "@/shared/components/base/BtnDropdown/index.vue";
import { useI18n } from "@/shared/composables/useI18n";
import {
  useSubscription,
  ChannelsEnum,
} from "@/shared/composables/useSubscription";
import { BtnSizesEnum } from "@/shared/components/base/Btn/types";
import { useRoadmapQueries } from "@/frontend/composables/useRoadmapQueries";
import RoadmapList from "@/frontend/components/Roadmap/List/index.vue";

const { t } = useI18n();

const released = ref(false);

const showRemoved = ref(false);

const releasedToggleLabel = computed(() => {
  if (released.value) {
    return t("actions.hideReleased");
  }

  return t("actions.showReleased");
});

const toggleRemovedTooltip = computed(() => {
  if (showRemoved.value) {
    return t("actions.roadmap.hideRemoved");
  }

  return t("actions.roadmap.showRemoved");
});

watch(
  () => released.value,
  () => {
    refetch();
  },
);

const toggleReleased = () => {
  released.value = !released.value;
};

const togglerShowRemoved = () => {
  showRemoved.value = !showRemoved.value;

  refetch();
};

const { listQuery } = useRoadmapQueries();

const filters = computed(() => {
  return {
    releasedEq: released.value,
    activeIn: [true, !showRemoved.value],
  };
});

const { data, refetch, ...asyncStatus } = listQuery(filters);

useSubscription({
  channelName: ChannelsEnum.ROADMAP,
  received: () => refetch(),
});
</script>

<template>
  <div class="row">
    <div class="col-12">
      <h1 class="sr-only">
        {{ t("headlines.roadmap") }}
      </h1>
    </div>
  </div>
  <Teleport to="#header-actions">
    <Btn :to="{ name: 'roadmap-changes' }" data-test="nav-roadmap-changes">
      <i class="fad fa-tasks" />
      <span>{{ t("nav.roadmap.changes") }}</span>
    </Btn>
    <Btn :to="{ name: 'roadmap-ships' }" data-test="nav-roadmap-ships">
      <i class="fad fa-starship" />
      <span>{{ t("nav.roadmap.ships") }}</span>
    </Btn>
    <Btn href="https://robertsspaceindustries.com/roadmap">
      {{ t("labels.rsiRoadmap") }}
    </Btn>
  </Teleport>
  <div class="row">
    <div class="col-3"></div>
    <div class="col-6">
      <div class="text-center">
        <a class="show-released" @click="toggleReleased">
          - {{ releasedToggleLabel }} -
        </a>
      </div>
    </div>
    <div class="col-3">
      <div class="d-flex justify-content-end">
        <BtnDropdown :size="BtnSizesEnum.SMALL">
          <Btn
            :size="BtnSizesEnum.SMALL"
            :active="showRemoved"
            :aria-label="toggleRemovedTooltip"
            @click="togglerShowRemoved"
          >
            <span v-if="showRemoved">
              <i class="fad fa-eye-slash"></i>
            </span>
            <span v-else>
              <i class="fad fa-eye"></i>
            </span>
            <span>{{ toggleRemovedTooltip }}</span>
          </Btn>
        </BtnDropdown>
      </div>
    </div>
  </div>

  <RoadmapList
    name="roadmap"
    :records="data || []"
    :async-status="asyncStatus"
    compact
  />
</template>

<style lang="scss" scoped>
@import "index";
</style>
