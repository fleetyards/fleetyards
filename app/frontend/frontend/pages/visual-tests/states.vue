<script lang="ts">
export default {
  name: "VisualTestsStatesPage",
};
</script>

<script lang="ts" setup>
import Btn from "@/shared/components/base/Btn/index.vue";
import BaseText from "@/shared/components/base/Text/index.vue";
import Empty from "@/shared/components/Empty/index.vue";
import InventoryPanel from "@/frontend/components/Logistics/InventoryPanel/index.vue";
import type { InventoryPanelRecord } from "@/frontend/types/logistics";
import Grid from "@/shared/components/base/Grid/index.vue";
import GridSkeleton from "@/shared/components/GridSkeleton/index.vue";
import ModelPanel from "@/frontend/components/Models/Panel/index.vue";
import ModelsTable from "@/frontend/components/Models/Table/index.vue";
import Loader from "@/shared/components/Loader/index.vue";
import Forbidden from "@/shared/components/Forbidden/index.vue";
import NotAuthorized from "@/shared/components/NotAuthorized/index.vue";
import NotFound from "@/shared/components/NotFound/index.vue";
import Paginator from "@/shared/components/Paginator/index.vue";
import Panel from "@/shared/components/base/Panel/index.vue";
import PanelBody from "@/shared/components/base/Panel/Body/index.vue";
import ProgressBar from "@/shared/components/ProgressBar/index.vue";
import UploadProgress from "@/shared/components/UploadProgress/index.vue";
import ServerError from "@/shared/components/ServerError/index.vue";
import SmallLoader from "@/shared/components/SmallLoader/index.vue";
import { EmptyVariantsEnum } from "@/shared/components/Empty/types";
import { HeadingLevelEnum } from "@/shared/components/base/Heading/types";
import {
  type BaseList,
  useModelsLatest as useLatestModelsQuery,
} from "@/services/fyApi";

const {
  data: latestModels,
  isFetching: latestModelsFetching,
  refetch: refetchLatestModels,
} = useLatestModelsQuery();

const skeletonDetails = ref(false);

const comparisonModels = computed(() => (latestModels.value || []).slice(0, 2));

const progress = ref(35);

const bumpProgress = () => {
  progress.value = progress.value >= 100 ? 0 : progress.value + 15;
};

const fixedLoaderVisible = ref(false);

let fixedLoaderTimer: ReturnType<typeof setTimeout> | undefined;

const showFixedLoader = () => {
  fixedLoaderVisible.value = true;

  clearTimeout(fixedLoaderTimer);
  fixedLoaderTimer = setTimeout(() => {
    fixedLoaderVisible.value = false;
  }, 2000);
};

onBeforeUnmount(() => {
  clearTimeout(fixedLoaderTimer);
});

const paginated: BaseList = {
  meta: {
    pagination: {
      totalCount: 248,
      currentPage: 1,
      totalPages: 10,
      perPage: 25,
      defaultPerPage: 25,
      maxPerPage: 100,
      perPageSteps: [25, 50, 100],
    },
  },
};

const singlePage: BaseList = {
  meta: {
    pagination: {
      totalCount: 8,
      currentPage: 1,
      totalPages: 1,
      perPage: 25,
      defaultPerPage: 25,
    },
  },
};

const emptyList: BaseList = {
  meta: {
    pagination: {
      totalCount: 0,
      currentPage: 1,
      totalPages: 0,
      perPage: 25,
      defaultPerPage: 25,
    },
  },
};

// The card the `summary` placeholders stand in for. Two of them, since the
// second line of a card - a ship's name against a written location - is where
// the heights of two cards in one row can differ.
const inventories: InventoryPanelRecord[] = [
  {
    id: "inventory-1",
    name: "Port Olisar Locker",
    slug: "port-olisar-locker",
    location: "Port Olisar",
    entriesCount: 24,
    totalScu: 118,
    totalUnits: 1420,
  },
  {
    id: "inventory-2",
    name: "Ironclad Hold",
    slug: "ironclad-hold",
    entriesCount: 8,
    totalScu: 384,
    totalUnits: 0,
    vehicle: {
      id: "vehicle-1",
      name: "Grey Hauler",
      model: { slug: "ironclad", cargo: 384, personalInventory: 0 },
    },
  },
];

const perPage = ref<number | string>(25);

const updatePerPage = (value: number | string) => {
  perPage.value = value;
};
</script>

<template>
  <Heading :level="HeadingLevelEnum.H2">Empty</Heading>
  <p>
    The no-records state. The <code>box</code> variant wraps itself in a large
    panel; the bare variant is for use inside one. Actions only appear when the
    route carries filters or a page — append <code>?page=2</code> to this URL to
    see them.
  </p>
  <div class="row">
    <div class="col-12 col-lg-6">
      <Empty :variant="EmptyVariantsEnum.BOX" name="Ships" />
    </div>
    <div class="col-12 col-lg-6">
      <Panel>
        <PanelBody>
          <Empty name="Ships" />
        </PanelBody>
      </Panel>
    </div>
  </div>
  <div class="row">
    <div class="col-12 col-lg-6">
      <Empty :variant="EmptyVariantsEnum.BOX" hide-actions />
    </div>
    <div class="col-12 col-lg-6">
      <Empty
        :variant="EmptyVariantsEnum.BOX"
        name="Docks"
        inline
        hide-actions
      />
    </div>
  </div>
  <div class="row">
    <div class="col-12 col-lg-6">
      <Empty :variant="EmptyVariantsEnum.BOX" hide-actions>
        <template #headline>A custom headline</template>
        <template #info>
          <BaseText muted>
            And custom info copy, replacing the default explanation.
          </BaseText>
        </template>
      </Empty>
    </div>
  </div>

  <Heading :level="HeadingLevelEnum.H3">Empty | In a narrow column</Heading>
  <p>
    The box is not always as wide as the page: the notification pages stand it
    in the list's own column, beside the reading pane. Its 600px is a ceiling
    rather than a width, and the headline wraps inside the box rather than
    running over whatever sits next to it.
  </p>
  <div class="vt-narrow-column" data-test="empty-narrow">
    <Empty :variant="EmptyVariantsEnum.BOX" hide-actions />
  </div>

  <Heading :level="HeadingLevelEnum.H3">
    GridSkeleton | The inventory cards
  </Heading>
  <p>
    The <code>summary</code> variant, beside the cards it stands in for. These
    stand on the same picture floor the ships card does, but carry a strip of
    figures at the bottom of the photo as well as a heading at the top of it —
    290px against 290px, which is the measurement the pair is here to keep
    honest.
  </p>
  <div class="row">
    <div class="col-12 col-lg-6">
      <BaseText muted no-spacing>cards</BaseText>
      <Grid :records="inventories" primary-key="id" grid-base="2">
        <template #default="{ record }">
          <InventoryPanel :inventory="record" :to="{ name: 'home' }" />
        </template>
      </Grid>
    </div>
    <div class="col-12 col-lg-6">
      <BaseText muted no-spacing>placeholders</BaseText>
      <GridSkeleton :count="2" variant="summary" grid-base="2" />
    </div>
  </div>

  <Heading :level="HeadingLevelEnum.H2">Loader</Heading>
  <p>
    The cube loader. <code>relative</code> and <code>inline</code> sit in the
    flow; <code>fixed</code> overlays the viewport, so it is behind a button.
    <code>progress</code> draws the two edge bars.
  </p>
  <div class="row">
    <div class="col-12 col-lg-3 vt-stack">
      <BaseText muted no-spacing>relative</BaseText>
      <Loader loading relative />
    </div>
    <div class="col-12 col-lg-3 vt-stack">
      <BaseText muted no-spacing>inline</BaseText>
      <Loader loading inline />
    </div>
    <div class="col-12 col-lg-3 vt-stack">
      <BaseText muted no-spacing>admin</BaseText>
      <Loader loading relative admin />
    </div>
    <div class="col-12 col-lg-3 vt-stack">
      <BaseText muted no-spacing>with progress ({{ progress }}%)</BaseText>
      <Loader loading relative :progress="progress" />
      <Btn data-test="bump-progress" @click="bumpProgress"> Advance </Btn>
    </div>
  </div>
  <div class="row">
    <div class="col-12">
      <Btn data-test="show-fixed-loader" @click="showFixedLoader">
        Show fixed loader (2s)
      </Btn>
      <Loader :loading="fixedLoaderVisible" fixed />
    </div>
  </div>

  <Heading :level="HeadingLevelEnum.H2">GridSkeleton</Heading>
  <p>
    The placeholder cards a grid list holds itself open with while it loads,
    beside the real cards that replace them - a placeholder of a different
    height moves the page under the reader once the records land, which is the
    whole thing it is there to prevent. <code>details</code> follows the display
    option the ships list carries.
  </p>
  <div class="row">
    <div class="col-12">
      <Btn
        data-test="toggle-skeleton-details"
        @click="skeletonDetails = !skeletonDetails"
      >
        {{ skeletonDetails ? "Hide details" : "Show details" }}
      </Btn>
    </div>
  </div>
  <div class="row">
    <div class="col-12 col-lg-6">
      <BaseText muted no-spacing>placeholders</BaseText>
      <GridSkeleton :count="2" :details="skeletonDetails" grid-base="2" />
    </div>
    <div class="col-12 col-lg-6">
      <BaseText muted no-spacing>the cards they stand in for</BaseText>
      <Grid :records="comparisonModels" primary-key="slug" grid-base="2">
        <template #default="{ record }">
          <ModelPanel :model="record" :details="skeletonDetails" />
        </template>
      </Grid>
    </div>
  </div>
  <p>
    The same list in table view: the placeholder rows are the real table with
    nothing in it yet, so the header, the column widths and the row height are
    the ones the records arrive into.
  </p>
  <div class="row">
    <div class="col-12 col-lg-6">
      <BaseText muted no-spacing>placeholder rows</BaseText>
      <ModelsTable :models="[]" loading :skeleton-rows="3" />
    </div>
    <div class="col-12 col-lg-6">
      <BaseText muted no-spacing>the rows they stand in for</BaseText>
      <ModelsTable :models="comparisonModels" />
    </div>
  </div>

  <Heading :level="HeadingLevelEnum.H2">SmallLoader</Heading>
  <p>The inline rhombus spinner, at each alignment.</p>
  <div class="row">
    <div class="col-12 col-lg-4">
      <BaseText muted no-spacing>left</BaseText>
      <SmallLoader loading alignment="left" />
    </div>
    <div class="col-12 col-lg-4">
      <BaseText muted no-spacing>center</BaseText>
      <SmallLoader loading alignment="center" />
    </div>
    <div class="col-12 col-lg-4">
      <BaseText muted no-spacing>right</BaseText>
      <SmallLoader loading alignment="right" />
    </div>
  </div>

  <Heading :level="HeadingLevelEnum.H2">ProgressBar</Heading>
  <p>Fill with a percentage label.</p>
  <div class="row">
    <div class="col-12 col-lg-6">
      <ProgressBar :progress="0" />
      <ProgressBar :progress="progress" />
      <ProgressBar :progress="100" />
    </div>
  </div>

  <Heading :level="HeadingLevelEnum.H2">Paginator</Heading>
  <p>
    Ten pages with a per-page dropdown, a single-page result, an empty result
    and the state before a list has answered. Page links write to the route, so
    clicking one navigates this page.
  </p>
  <div class="row">
    <div class="col-12 vt-stack">
      <Paginator
        :query-result-ref="paginated"
        :per-page="perPage"
        :update-per-page="updatePerPage"
      />
      <Paginator :query-result-ref="paginated" inline />
      <Paginator :query-result-ref="singlePage" />
      <Paginator :query-result-ref="emptyList" />
      <Paginator :query-result-ref="undefined" />
    </div>
  </div>

  <Heading :level="HeadingLevelEnum.H2">UploadProgress</Heading>
  <p>
    The striped bar a direct upload draws. <code>active</code> animates the
    stripes; <code>error</code> is what a failed upload leaves behind, which has
    to stay on screen rather than resetting to nothing.
  </p>
  <div class="row">
    <div class="col-12 col-lg-4">
      <BaseText muted no-spacing>idle at 0</BaseText>
      <UploadProgress />
    </div>
    <div class="col-12 col-lg-4">
      <BaseText muted no-spacing>active at {{ progress }}%</BaseText>
      <UploadProgress :progress="progress" active />
    </div>
    <div class="col-12 col-lg-4">
      <BaseText muted no-spacing>failed part-way</BaseText>
      <UploadProgress :progress="progress" error />
    </div>
  </div>
  <div class="row">
    <div class="col-12 col-lg-4">
      <BaseText muted no-spacing>complete</BaseText>
      <UploadProgress :progress="100" />
    </div>
  </div>

  <Heading :level="HeadingLevelEnum.H2">Error Pages</Heading>
  <p>
    The four full-page error blocks. They are normally rendered as a whole
    route, so they bring their own heading. <code>Forbidden</code> is the one
    for a resource that exists and is not yours, as against
    <code>NotAuthorized</code> for not being signed in at all.
  </p>
  <NotFound />
  <NotAuthorized />
  <Forbidden />
  <ServerError />

  <Heading :level="HeadingLevelEnum.H2">FetchProgressBar</Heading>
  <p>
    The top-of-viewport bar is driven by the global in-flight query count, not
    by props — it is already mounted app-wide. Refetching a real query runs it.
  </p>
  <div class="row">
    <div class="col-12">
      <Btn
        :disabled="latestModelsFetching"
        data-test="trigger-fetch"
        @click="refetchLatestModels"
      >
        Refetch latest models
      </Btn>
    </div>
  </div>
</template>

<style lang="scss" scoped>
// The width the notifications list column has on a desktop, which is where the
// box was overflowing.
.vt-narrow-column {
  width: 361px;
  outline: 1px dashed rgba(#fff, 0.15);
}
</style>
