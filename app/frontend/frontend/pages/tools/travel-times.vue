<script lang="ts">
export default {
  name: "ToolsTravelTimesPage",
};
</script>

<script lang="ts" setup>
import Heading from "@/shared/components/base/Heading/index.vue";
import { HeadingLevelEnum } from "@/shared/components/base/Heading/types";
import Panel from "@/shared/components/base/Panel/index.vue";
import PanelHeading from "@/shared/components/base/Panel/Heading/index.vue";
import PanelBody from "@/shared/components/base/Panel/Body/index.vue";
import Slider from "@/shared/components/base/Slider/index.vue";
import Chip from "@/shared/components/base/Chip/index.vue";
import { ChipStatesEnum } from "@/shared/components/base/Chip/types";
import { useI18n } from "@/shared/composables/useI18n";
import { useFilters } from "@/shared/composables/useFilters";
import FormInput from "@/shared/components/base/FormInput/index.vue";
import FilteredList from "@/shared/components/FilteredList/index.vue";
import BaseTable from "@/shared/components/base/Table/index.vue";
import {
  type BaseTableCol,
  BaseTableColAlignmentEnum,
} from "@/shared/components/base/Table/types";
import TravelTime from "@/frontend/components/TravelTime/index.vue";
import {
  useComponents as useComponentsQuery,
  type ComponentQuantumDrive,
  type Component,
} from "@/services/fyApi";
import { quantumDriveTravelTime } from "@/frontend/utils/travelTimes";
import {
  InputTypesEnum,
  InputAlignmentsEnum,
} from "@/shared/components/base/FormInput/types";
import FeatureGuard from "@/frontend/components/FeatureGuard.vue";
import { FeatureFlagName } from "@/services/fyApi";

const { t, toNumber } = useI18n();

const route = useRoute();

/*
 * Distance, filters and order all live in the URL, so a link reproduces exactly
 * what the sender was looking at -- the same contract every other filtered list
 * in the app keeps. `s` is written by the table's own SortableLink; the rest is
 * `useFilters`, which reads every query key that is not `s`, `page` or `perPage`.
 */
type TravelTimesFilters = {
  distance?: string;
  size?: string;
  grade?: string;
};

const DEFAULT_DISTANCE = 20;
const DEFAULT_SORT = "travel_time asc";

const { filters, filter } = useFilters<TravelTimesFilters>();

const numberList = (value?: string) =>
  (value || "")
    .split(",")
    .map((item) => Number(item))
    .filter((item) => !Number.isNaN(item) && item > 0);

const stringList = (value?: string) =>
  (value || "").split(",").filter((item) => item.length > 0);

const distance = ref(Number(route.query.distance) || DEFAULT_DISTANCE);

// Millions of kilometres. The far end is a little past the widest jump Stanton
// offers, so the whole range a player meets sits inside the track.
const DISTANCE_MIN = 1;
const DISTANCE_MAX = 120;

const PRESETS = [
  { key: "moon", mkm: 0.4 },
  { key: "short", mkm: 8 },
  { key: "system", mkm: 40 },
  { key: "far", mkm: 90 },
];

const SIZES = [1, 2, 3, 4];
const GRADES = ["A", "B", "C", "D"];

const sizeFilter = ref<number[]>(numberList(route.query.size as string));
const gradeFilter = ref<string[]>(stringList(route.query.grade as string));

/*
 * Held locally as well as in the URL: `filter` is debounced, and a chip whose
 * own pressed state waited on the address bar would feel broken. The two
 * watchers below keep the pair honest in both directions.
 */
watch([distance, sizeFilter, gradeFilter], () => {
  filter({
    distance:
      distance.value === DEFAULT_DISTANCE ? undefined : String(distance.value),
    size: sizeFilter.value.length ? sizeFilter.value.join(",") : undefined,
    grade: gradeFilter.value.length ? gradeFilter.value.join(",") : undefined,
  });
});

// The other direction: a pasted link, or the back button.
watch(
  () => filters.value,
  (next) => {
    const nextDistance = Number(next.distance) || DEFAULT_DISTANCE;
    if (nextDistance !== distance.value) {
      distance.value = nextDistance;
    }

    const nextSizes = numberList(next.size);
    if (nextSizes.join(",") !== sizeFilter.value.join(",")) {
      sizeFilter.value = nextSizes;
    }

    const nextGrades = stringList(next.grade);
    if (nextGrades.join(",") !== gradeFilter.value.join(",")) {
      gradeFilter.value = nextGrades;
    }
  },
  { deep: true },
);

const sort = computed(() => {
  const [field, direction] = String(route.query.s || DEFAULT_SORT).split(" ");

  return { field, direction: direction === "desc" ? "desc" : "asc" };
});

const filtered = computed(
  () => sizeFilter.value.length > 0 || gradeFilter.value.length > 0,
);

// Refs unwrap in the template, so these take the value rather than the ref --
// a generic helper reading `.value` cannot be called from there.
const toggleSize = (size: number) => {
  sizeFilter.value = sizeFilter.value.includes(size)
    ? sizeFilter.value.filter((item) => item !== size)
    : [...sizeFilter.value, size];
};

const toggleGrade = (grade: string) => {
  gradeFilter.value = gradeFilter.value.includes(grade)
    ? gradeFilter.value.filter((item) => item !== grade)
    : [...gradeFilter.value, grade];
};

const clearFilters = () => {
  sizeFilter.value = [];
  gradeFilter.value = [];
};

const isQuantumDrive = (
  typeData?: Component["typeData"],
): typeData is ComponentQuantumDrive => {
  return !!typeData && "quantumFuelConsumption" in typeData;
};

/*
 * Quantum fuel burnt over the jump, in SCU. `quantumFuelConsumption` is
 * milli-SCU per Gm, and a Gm is a million kilometres -- the same unit the
 * distance is collected in -- so the jump costs rate * distance milli-SCU.
 *
 * The drive also carries `quantumFuelRequirement`, which this column used to
 * read. Nothing else in the app touches that field and no unit is declared for
 * it anywhere; the consumption figure is the one the hardpoint panel derives
 * its jump range from, checked against erkul.games and spviewer.eu.
 */
const fuelUsage = (component: Component): number | undefined => {
  if (!isQuantumDrive(component.typeData)) {
    return undefined;
  }

  const rate = component.typeData.quantumFuelConsumption;

  return rate
    ? Math.round(((rate * distance.value) / 1000) * 100) / 100
    : undefined;
};

const gradeOf = (component: Component) => component.gradeLabel || "";

const sizeOf = (component: Component) => Number(component.size) || 0;

const componentsQueryParams = computed(() => ({
  page: "1",
  perPage: "240",
  q: {
    categoryIn: ["quantumdrive"],
  },
}));

const { data: quantumDrives, ...asyncStatus } = useComponentsQuery(
  componentsQueryParams,
);

/*
 * Five of the sixty-three rows the catalogue returns have no name: four are the
 * game files' own `qdrv_s0*_template` entries and the fifth is the Javelin's
 * bespoke drive. None is a drive anyone can fit, and unnamed they would render
 * as blank rows carrying a rank.
 */
const drives = computed(() =>
  (quantumDrives.value?.items || []).filter((drive) => !!drive.name),
);

/*
 * Seconds per drive, computed once per distance change and read by the sort,
 * the bar and the rank. The cell renders its own through the same helper, so
 * there is no second interpretation of the numbers -- only a second call.
 */
const secondsBySlug = computed(() => {
  const result: Record<string, number | undefined> = {};

  drives.value.forEach((drive) => {
    result[drive.slug] = quantumDriveTravelTime(drive, distance.value);
  });

  return result;
});

/*
 * The bar measures against the slowest drive there is, not the slowest one left
 * after filtering -- a bar whose scale moves as you filter says nothing you can
 * carry from one view to the next.
 */
const slowest = computed(() =>
  Object.values(secondsBySlug.value).reduce<number>(
    (max, seconds) => (seconds && seconds > max ? seconds : max),
    0,
  ),
);

const barPercent = (component: Component) => {
  const seconds = secondsBySlug.value[component.slug];

  if (!seconds || !slowest.value) {
    return 0;
  }

  return Math.max(3, Math.round((seconds / slowest.value) * 100));
};

const visibleDrives = computed(() => {
  let list = drives.value;

  if (sizeFilter.value.length) {
    list = list.filter((drive) => sizeFilter.value.includes(sizeOf(drive)));
  }

  if (gradeFilter.value.length) {
    list = list.filter((drive) => gradeFilter.value.includes(gradeOf(drive)));
  }

  const direction = sort.value.direction === "asc" ? 1 : -1;

  return [...list].sort((a, b) => {
    switch (sort.value.field) {
      case "name":
        return a.name.localeCompare(b.name) * direction;
      case "size":
        return (sizeOf(a) - sizeOf(b)) * direction;
      case "grade":
        return gradeOf(a).localeCompare(gradeOf(b)) * direction;
      case "fuel_usage":
        return ((fuelUsage(a) ?? 0) - (fuelUsage(b) ?? 0)) * direction;
      default: {
        // A drive the export never described has no time; it sorts last either
        // way rather than jumping to the top when the direction flips.
        const aSeconds = secondsBySlug.value[a.slug];
        const bSeconds = secondsBySlug.value[b.slug];

        if (!aSeconds) return 1;
        if (!bSeconds) return -1;

        return (aSeconds - bSeconds) * direction;
      }
    }
  });
});

// The rank only means "fastest" while the list is ordered by time, so the
// podium colour is held back otherwise -- the number stays as the row's place.
const byTime = computed(
  () => sort.value.field === "travel_time" && sort.value.direction === "asc",
);

const rankOf = (component: Component) =>
  visibleDrives.value.findIndex((drive) => drive.slug === component.slug) + 1;

const columns = computed<BaseTableCol<Component>[]>(() => {
  return [
    {
      name: "rank",
      label: t("labels.travelTimes.rank"),
      class: "rank",
      width: "56px",
    },
    {
      name: "name",
      label: t("labels.travelTimes.quantumDrive"),
      class: "name",
      sortable: true,
    },
    {
      name: "size",
      label: t("labels.travelTimes.size"),
      class: "size",
      width: "76px",
      alignment: BaseTableColAlignmentEnum.RIGHT,
      sortable: true,
      mobile: false,
    },
    {
      name: "grade",
      label: t("labels.travelTimes.grade"),
      class: "grade",
      width: "76px",
      alignment: BaseTableColAlignmentEnum.RIGHT,
      sortable: true,
      mobile: false,
    },
    {
      name: "fuel_usage",
      label: t("labels.travelTimes.fuelUsage"),
      class: "fuel-usage",
      width: "116px",
      alignment: BaseTableColAlignmentEnum.RIGHT,
      sortable: true,
    },
    {
      name: "travel_time",
      label: t("labels.travelTimes.travelTime"),
      class: "travel-time",
      width: "116px",
      alignment: BaseTableColAlignmentEnum.RIGHT,
      sortable: true,
    },
  ];
});
</script>

<template>
  <FeatureGuard :feature="FeatureFlagName.TOOLS_TRAVEL_TIMES">
    <Heading hero>{{ t(`headlines.${route.meta.title}`) }}</Heading>

    <p class="travel-times__intro">
      {{ t("labels.travelTimes.intro") }}
    </p>

    <div class="row">
      <div class="col-12 col-md-4">
        <Panel>
          <PanelHeading :level="HeadingLevelEnum.H2">
            {{ t("labels.travelTimes.jumpDistance") }}
          </PanelHeading>
          <PanelBody>
            <FormInput
              v-model.number="distance"
              class="travel-times__distance"
              :min="DISTANCE_MIN"
              name="distance"
              :type="InputTypesEnum.NUMBER"
              :alignment="InputAlignmentsEnum.RIGHT"
              suffix="Mkm"
              no-label
            />

            <Slider
              v-model="distance"
              :min="DISTANCE_MIN"
              :max="DISTANCE_MAX"
              class="travel-times__slider"
            />

            <div class="travel-times__presets">
              <Chip
                v-for="preset in PRESETS"
                :key="preset.key"
                :state="
                  distance === preset.mkm
                    ? ChipStatesEnum.INCLUDED
                    : ChipStatesEnum.NEUTRAL
                "
                @toggle="distance = preset.mkm"
              >
                {{ t(`labels.travelTimes.presets.${preset.key}`) }}
                <span class="travel-times__preset-value">
                  {{ preset.mkm }}
                </span>
              </Chip>
            </div>

            <p class="travel-times__hint">
              {{ t("labels.travelTimes.distanceHint") }}
            </p>
          </PanelBody>
        </Panel>

        <Panel>
          <PanelHeading :level="HeadingLevelEnum.H2">
            {{ t("labels.travelTimes.filters") }}
            <template #actions>
              <button
                v-if="filtered"
                type="button"
                class="travel-times__reset"
                @click="clearFilters"
              >
                {{ t("labels.travelTimes.resetFilters") }}
              </button>
            </template>
          </PanelHeading>
          <PanelBody>
            <div class="travel-times__filter-label">
              {{ t("labels.travelTimes.size") }}
            </div>
            <div class="travel-times__chips">
              <Chip
                v-for="size in SIZES"
                :key="`size-${size}`"
                :state="
                  sizeFilter.includes(size)
                    ? ChipStatesEnum.INCLUDED
                    : ChipStatesEnum.NEUTRAL
                "
                @toggle="toggleSize(size)"
              >
                {{ t("labels.travelTimes.sizeValue", { size }) }}
              </Chip>
            </div>

            <div class="travel-times__filter-label">
              {{ t("labels.travelTimes.grade") }}
            </div>
            <div class="travel-times__chips">
              <Chip
                v-for="grade in GRADES"
                :key="`grade-${grade}`"
                :state="
                  gradeFilter.includes(grade)
                    ? ChipStatesEnum.INCLUDED
                    : ChipStatesEnum.NEUTRAL
                "
                @toggle="toggleGrade(grade)"
              >
                {{ grade }}
              </Chip>
            </div>
          </PanelBody>
        </Panel>

        <p class="travel-times__credit">
          {{ t("labels.travelTimes.poweredBy") }}
          <a
            href="https://gitlab.com/Erecco/a-study-on-quantum-travel-time/-/blob/master/A_study_on_Quantum_Travel_time_07042021.pdf?ref_type=heads"
            >Erec</a
          >
        </p>
      </div>

      <div class="col-12 col-md-8">
        <div class="travel-times__meta">
          <span>
            {{
              filtered
                ? t("labels.travelTimes.countFiltered", {
                    count: visibleDrives.length,
                    total: drives.length,
                  })
                : t("labels.travelTimes.count", { count: drives.length })
            }}
          </span>
        </div>

        <FilteredList
          key="quantumDrives"
          :records="visibleDrives"
          :name="route.name?.toString() || ''"
          :async-status="asyncStatus"
        >
          <template #default="{ records }">
            <BaseTable
              :records="records"
              :filter-visible="false"
              primary-key="slug"
              :columns="columns"
              :default-sort="DEFAULT_SORT"
            >
              <template #col-rank="{ record }">
                <span
                  class="travel-times__rank"
                  :class="{
                    'travel-times__rank--podium': byTime && rankOf(record) <= 3,
                  }"
                >
                  {{ String(rankOf(record)).padStart(2, "0") }}
                </span>
              </template>

              <template #col-name="{ record }">
                <div class="travel-times__drive">
                  <span>{{ record.name }}</span>
                  <span class="travel-times__bar">
                    <span
                      class="travel-times__bar-fill"
                      :class="{
                        'travel-times__bar-fill--podium':
                          byTime && rankOf(record) <= 3,
                      }"
                      :style="{ width: `${barPercent(record)}%` }"
                    />
                  </span>
                </div>
              </template>

              <template #col-size="{ record }">
                <span class="travel-times__badge">
                  {{
                    t("labels.travelTimes.sizeValue", { size: sizeOf(record) })
                  }}
                </span>
              </template>

              <template #col-grade="{ record }">
                <span
                  v-if="gradeOf(record)"
                  class="travel-times__badge"
                  :class="`travel-times__badge--grade-${gradeOf(record).toLowerCase()}`"
                >
                  {{ gradeOf(record) }}
                </span>
                <template v-else> - </template>
              </template>

              <template #col-fuel_usage="{ record }">
                <template v-if="fuelUsage(record)">
                  {{ toNumber(fuelUsage(record)!, "cargo") }}
                </template>
                <template v-else> - </template>
              </template>

              <template #col-travel_time="{ record }">
                <TravelTime
                  class="travel-times__time"
                  :quantum-drive="record"
                  :distance="distance"
                />
              </template>

              <template #empty>
                <div class="travel-times__empty">
                  <span>{{ t("labels.travelTimes.noMatch") }}</span>
                  <button
                    type="button"
                    class="travel-times__reset"
                    @click="clearFilters"
                  >
                    {{ t("labels.travelTimes.resetFilters") }}
                  </button>
                </div>
              </template>
            </BaseTable>
          </template>
        </FilteredList>

        <p class="travel-times__legend">
          {{ t("labels.travelTimes.barLegend") }}
        </p>
      </div>
    </div>
  </FeatureGuard>
</template>

<style lang="scss" scoped>
@import "./travel-times.scss";
</style>
