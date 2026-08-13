<script lang="ts">
export default {
  name: "VisualTestsStatesPage",
};
</script>

<script lang="ts" setup>
import Btn from "@/shared/components/base/Btn/index.vue";
import BaseText from "@/shared/components/base/Text/index.vue";
import Empty from "@/shared/components/Empty/index.vue";
import Loader from "@/shared/components/Loader/index.vue";
import NotAuthorized from "@/shared/components/NotAuthorized/index.vue";
import NotFound from "@/shared/components/NotFound/index.vue";
import Paginator from "@/shared/components/Paginator/index.vue";
import Panel from "@/shared/components/base/Panel/index.vue";
import PanelBody from "@/shared/components/base/Panel/Body/index.vue";
import ProgressBar from "@/shared/components/ProgressBar/index.vue";
import ServerError from "@/shared/components/ServerError/index.vue";
import SmallLoader from "@/shared/components/SmallLoader/index.vue";
import { BtnSizesEnum } from "@/shared/components/base/Btn/types";
import { EmptyVariantsEnum } from "@/shared/components/Empty/types";
import { HeadingLevelEnum } from "@/shared/components/base/Heading/types";
import {
  type BaseList,
  useModelsLatest as useLatestModelsQuery,
} from "@/services/fyApi";

const { isFetching: latestModelsFetching, refetch: refetchLatestModels } =
  useLatestModelsQuery();

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

  <Heading :level="HeadingLevelEnum.H2">Loader</Heading>
  <p>
    The cube loader. <code>relative</code> and <code>inline</code> sit in the
    flow; <code>fixed</code> overlays the viewport, so it is behind a button.
    <code>progress</code> draws the two edge bars.
  </p>
  <div class="row">
    <div class="col-12 col-lg-3">
      <BaseText muted no-spacing>relative</BaseText>
      <Loader loading relative />
    </div>
    <div class="col-12 col-lg-3">
      <BaseText muted no-spacing>inline</BaseText>
      <Loader loading inline />
    </div>
    <div class="col-12 col-lg-3">
      <BaseText muted no-spacing>admin</BaseText>
      <Loader loading relative admin />
    </div>
    <div class="col-12 col-lg-3">
      <BaseText muted no-spacing>with progress ({{ progress }}%)</BaseText>
      <Loader loading relative :progress="progress" />
      <Btn
        :size="BtnSizesEnum.SMALL"
        data-test="bump-progress"
        @click="bumpProgress"
      >
        Advance
      </Btn>
    </div>
  </div>
  <div class="row">
    <div class="col-12">
      <Btn
        :size="BtnSizesEnum.SMALL"
        data-test="show-fixed-loader"
        @click="showFixedLoader"
      >
        Show fixed loader (2s)
      </Btn>
      <Loader :loading="fixedLoaderVisible" fixed />
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
    Ten pages with a per-page dropdown, and a single-page result. Page links
    write to the route, so clicking one navigates this page.
  </p>
  <div class="row">
    <div class="col-12">
      <Paginator
        :query-result-ref="paginated"
        :per-page="perPage"
        :update-per-page="updatePerPage"
      />
    </div>
  </div>
  <div class="row">
    <div class="col-12">
      <Paginator :query-result-ref="paginated" inline />
    </div>
  </div>
  <div class="row">
    <div class="col-12">
      <Paginator :query-result-ref="singlePage" />
    </div>
  </div>

  <Heading :level="HeadingLevelEnum.H2">Error Pages</Heading>
  <p>
    The three full-page error blocks. They are normally rendered as a whole
    route, so they bring their own heading.
  </p>
  <NotFound />
  <NotAuthorized />
  <ServerError />

  <Heading :level="HeadingLevelEnum.H2">FetchProgressBar</Heading>
  <p>
    The top-of-viewport bar is driven by the global in-flight query count, not
    by props — it is already mounted app-wide. Refetching a real query runs it.
  </p>
  <div class="row">
    <div class="col-12">
      <Btn
        :size="BtnSizesEnum.SMALL"
        :disabled="latestModelsFetching"
        data-test="trigger-fetch"
        @click="refetchLatestModels"
      >
        Refetch latest models
      </Btn>
    </div>
  </div>
</template>
