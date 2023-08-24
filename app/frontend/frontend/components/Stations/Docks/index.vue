<template>
  <div
    v-if="station.docks?.length"
    class="row"
    :class="{
      'metrics-padding': padding,
    }"
  >
    <div class="col-12 col-lg-3">
      <div class="metrics-title">
        {{ t("labels.station.docks") }}
      </div>
    </div>
    <div class="col-12 col-lg-9 metrics-block">
      <div class="row">
        <template v-if="hasGroup">
          <div
            v-for="(groupDocks, group) in docksByGroup"
            :key="`docks-${group}`"
            class="col-12"
          >
            <div class="metrics-group-label">
              <b>{{ group }}:</b>
            </div>
            <div class="row">
              <div
                v-for="(typedDocks, type) in docksByType(groupDocks)"
                :key="`docks-${group}-${type}`"
                class="col-12"
              >
                <div class="metrics-label">
                  <b>{{ type }}:</b>
                </div>
                <div class="row">
                  <div
                    v-for="(docks, size) in docksBySize(typedDocks)"
                    :key="`dock-${size}`"
                    class="col-6"
                  >
                    <DockItem :docks="docks" :size="size" />
                  </div>
                </div>
              </div>
            </div>
          </div>
        </template>
        <div
          v-for="(groupDocks, group) in docksByType(station.docks)"
          v-else
          :key="`docks-${group}`"
          class="col-12"
        >
          <div class="metrics-label">
            <b>{{ group }}:</b>
          </div>
          <div class="row">
            <div
              v-for="(docks, size) in docksBySize(groupDocks)"
              :key="`dock-${size}`"
              class="col-6"
            >
              <DockItem :docks="docks" :size="size" />
            </div>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script lang="ts" setup>
import { groupBy, sortBy } from "@/shared/utils/Array";
import DockItem from "./Item/index.vue";
import { useI18n } from "@/frontend/composables/useI18n";
import type { Station, Dock } from "@/services/fyApi";

type Props = {
  station: Station;
  padding?: boolean;
};

const props = withDefaults(defineProps<Props>(), {
  padding: false,
});

const { t } = useI18n();

const hasGroup = computed(() => {
  return props.station.docks?.some((dock) => !!dock.group);
});

const sortedDocks = computed(() => {
  return sortBy<Dock>(props.station.docks || [], "name");
});

const docksByGroup = computed(() => {
  return groupBy(sortedDocks.value, "group") as Record<string, Dock[]>;
});

const docksBySize = (docks: Dock[]) => {
  return groupBy(docks, "sizeLabel") as Record<string, Dock[]>;
};

const docksByType = (docks: Dock[]) => {
  return groupBy(docks, "typeLabel") as Record<string, Dock[]>;
};
</script>

<script lang="ts">
export default {
  name: "StationsDocks",
};
</script>
