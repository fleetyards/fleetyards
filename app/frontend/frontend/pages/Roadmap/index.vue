<template>
  <router-view v-if="isSubRoute" />
  <section v-else class="container roadmap">
    <div class="row">
      <div class="col-12">
        <h1 class="sr-only">
          {{ $t("headlines.roadmap") }}
        </h1>
      </div>
    </div>
    <div class="row">
      <div class="col-12">
        <div class="page-actions page-actions-right">
          <Btn
            :to="{ name: 'roadmap-changes' }"
            data-test="nav-roadmap-changes"
          >
            <i class="fad fa-tasks" />
            {{ $t("nav.roadmap.changes") }}
          </Btn>
          <Btn :to="{ name: 'roadmap-ships' }" data-test="nav-roadmap-ships">
            <i class="fad fa-starship" />
            {{ $t("nav.roadmap.ships") }}
          </Btn>
          <Btn href="https://robertsspaceindustries.com/roadmap">
            {{ $t("labels.rsiRoadmap") }}
          </Btn>
        </div>
      </div>
    </div>
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
          <BtnDropdown size="small">
            <Btn
              size="small"
              variant="dropdown"
              :active="showRemoved"
              :aria-label="toggleRemovedTooltip"
              @click.native="togglerShowRemoved"
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
    <div class="row">
      <div class="col-12">
        <transition-group name="fade-list" class="row" tag="div" appear>
          <div
            v-for="(items, release) in groupedByRelease"
            :key="`releases-${release}`"
            class="col-12 fade-list-item release"
          >
            <h2
              :class="{
                open: visible.includes(release),
              }"
              class="toggleable"
              @click="toggle(release)"
            >
              <span class="title">{{ release }}</span>
              <span v-if="items[0].releaseDescription" class="released-label">
                ({{ items[0].releaseDescription }})
              </span>
              <small class="text-muted">
                {{ $t("labels.roadmap.stories", { count: items.length }) }}
              </small>
              <i class="fa fa-chevron-right" />
            </h2>

            <BCollapse
              :id="`${release}-cards`"
              :visible="visible.includes(release)"
            >
              <div class="row">
                <div
                  v-for="item in items"
                  :key="item.id"
                  class="col-12 col-lg-6 col-xl-4 col-xxl-2dot4 fade-list-item"
                >
                  <RoadmapItem :item="item" />
                </div>
              </div>
            </BCollapse>
          </div>
        </transition-group>
        <EmptyBox :visible="emptyBoxVisible" />
        <Loader :loading="loading" :fixed="true" />
      </div>
    </div>
  </section>
</template>

<script lang="ts">
// import Vue from "vue";
// import { Component, Watch } from "vue-property-decorator";
// import { BCollapse } from "bootstrap-vue";
import Btn from "@/frontend/core/components/Btn/index.vue";
import Loader from "@/frontend/core/components/Loader/index.vue";
import RoadmapItem from "@/frontend/components/Roadmap/RoadmapItem/index.vue";
import EmptyBox from "@/frontend/core/components/EmptyBox/index.vue";
import BtnDropdown from "@/frontend/core/components/BtnDropdown/index.vue";

@Component<RoadmapReleases>({
  components: {
    BCollapse,
    Loader,
    EmptyBox,
    RoadmapItem,
    Btn,
    BtnDropdown,
  },
})
export default class RoadmapReleases extends Vue {
  loading = true;

  onlyReleased = true;

  showRemoved = false;

  // TODO: replace with collection
  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  roadmapItems: any[] = [];

  visible: string[] = [];

  roadmapChannel = null;

  get releasedToggleLabel() {
    if (this.onlyReleased) {
      return this.$t("actions.showReleased");
    }

    return this.$t("actions.hideReleased");
  }

  get toggleRemovedTooltip() {
    if (this.showRemoved) {
      return this.$t("actions.roadmap.hideRemoved");
    }

    return this.$t("actions.roadmap.showRemoved");
  }

  get isSubRoute() {
    return this.$route.name !== "roadmap";
  }

  get emptyBoxVisible() {
    return !this.loading && this.roadmapItems.length === 0;
  }

  get filteredItems() {
    if (this.onlyReleased) {
      return this.roadmapItems.filter((item) => !item.released);
    }

    return this.roadmapItems;
  }

  get groupedByRelease() {
    return this.filteredItems.reduce((rv, x) => {
      const value = JSON.parse(JSON.stringify(rv));

      value[x.release] = rv[x.release] || [];
      value[x.release].push(x);

      return value;
    }, {});
  }

  get otherModels() {
    return this.models;
  }

  get modelsOnRoadmap() {
    return this.roadmapItems
      .filter((item) => item.model)
      .map((item) => item.model.id)
      .filter((item) => item);
  }

  mounted() {
    this.fetch();
    this.setupUpdates();
  }

  @Watch("onlyReleased")
  onOnlyReleasedChange() {
    this.fetch();
  }

  beforeDestroy() {
    if (this.roadmapChannel) {
      this.roadmapChannel.unsubscribe();
    }
  }

  tasks(items) {
    return items
      .filter((item) => item.active)
      .map((item) => Math.max(0, item.tasks))
      .reduce((ac, count) => ac + count, 0);
  }

  completed(items) {
    return items
      .map((item) => Math.max(0, item.completed))
      .reduce((ac, count) => ac + count, 0);
  }

  progressLabel(items) {
    return `${this.completed(items)} ${this.$t("labels.roadmap.tasks", {
      count: this.tasks(items),
    })}`;
  }

  completedPercent(items) {
    if (!this.tasks(items)) {
      return "?";
    }

    return Math.round((100 * this.completed(items)) / this.tasks(items));
  }

  setupUpdates() {
    if (this.roadmapChannel) {
      this.roadmapChannel.unsubscribe();
    }

    this.roadmapChannel = this.$cable.consumer.subscriptions.create(
      {
        channel: "RoadmapChannel",
      },
      {
        received: this.fetch,
      }
    );
  }

  toggleReleased() {
    this.onlyReleased = !this.onlyReleased;
  }

  togglerShowRemoved() {
    this.showRemoved = !this.showRemoved;
    this.fetch();
  }

  toggle(release) {
    if (this.visible.includes(release)) {
      const index = this.visible.indexOf(release);
      this.visible.splice(index, 1);

      return null;
    }

    return this.visible.push(release);
  }

  openReleased() {
    Object.keys(this.groupedByRelease).forEach((release) => {
      const items = this.groupedByRelease[release];

      if (items.length && !items[0].released) {
        this.visible.push(release);
      }
    });
  }

  async fetch() {
    this.loading = true;

    const response = await this.$api.get("roadmap?overview=1", {
      q: {
        activeIn: [true, !this.showRemoved],
        rsiReleaseIdGteq: this.onlyReleased ? 41 : 1,
      },
    });

    this.loading = false;

    if (!response.error) {
      this.roadmapItems = response.data;
      this.openReleased();
    }
  }
}
</script>
