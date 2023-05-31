<template>
  <section class="container hangar wishlist">
    <div class="row">
      <div class="col-12">
        <div class="row">
          <div class="col-12">
            <BreadCrumbs
              :crumbs="[{ to: { name: 'hangar' }, label: $t('nav.hangar') }]"
            />
            <div class="flex justify-between">
              <h1>
                {{ $t("headlines.hangar.wishlist") }}
              </h1>
              <ShareBtn
                v-if="!mobile && currentUser && currentUser.publicWishlist"
                :url="shareUrl"
                :title="metaTitle"
              />
            </div>
          </div>
        </div>
        <div class="hangar-header">
          <div class="hangar-labels"></div>
          <div v-if="!mobile" class="page-actions page-actions-right"></div>
        </div>
      </div>
    </div>

    <FilteredList
      key="wishlist"
      :collection="collection"
      :name="$route.name"
      :route-query="$route.query"
      :hash="$route.hash"
      :hide-empty-box="!gridView"
      :paginated="true"
    >
      <template #actions>
        <BtnDropdown size="small">
          <template v-if="mobile">
            <ShareBtn
              v-if="currentUser && currentUser.publicWishlist"
              :url="shareUrl"
              :title="metaTitle"
              size="small"
              variant="dropdown"
            />

            <hr />
          </template>

          <Btn
            :aria-label="toggleGridView"
            size="small"
            variant="dropdown"
            @click.native="toggleGridView"
          >
            <i v-if="gridView" class="fad fa-list" />
            <i v-else class="fas fa-th" />
            <span>{{ toggleGridViewTooltip }}</span>
          </Btn>

          <Btn
            v-if="gridView"
            :aria-label="toggleDetailsTooltip"
            size="small"
            variant="dropdown"
            @click.native="toggleDetails"
          >
            <i class="fad fa-info-square" />
            <span>{{ toggleDetailsTooltip }}</span>
          </Btn>

          <hr />

          <Btn
            size="small"
            variant="dropdown"
            :aria-label="$t('actions.export')"
            @click.native="exportJson"
          >
            <i class="fal fa-download" />
            <span>{{ $t("actions.export") }}</span>
          </Btn>

          <hr />

          <Btn
            size="small"
            variant="dropdown"
            :disabled="deleting"
            :aria-label="$t('actions.hangar.destroyAll')"
            @click.native="destroyAll"
          >
            <i class="fal fa-trash" />
            <span>{{ $t("actions.hangar.destroyAll") }}</span>
          </Btn>
        </BtnDropdown>
      </template>

      <VehiclesFilterForm slot="filter" />

      <template #default="{ records, filterVisible, primaryKey }">
        <FilteredGrid
          v-if="gridView"
          :records="records"
          :filter-visible="filterVisible"
          :primary-key="primaryKey"
        >
          <template #default="{ record }">
            <VehiclePanel
              :vehicle="record"
              :details="detailsVisible"
              :editable="true"
              :wishlist="true"
            />
          </template>
        </FilteredGrid>

        <VehiclesTable
          v-else
          :vehicles="records"
          :primary-key="primaryKey"
          :editable="true"
          :wishlist="true"
        />
      </template>

      <template #empty="{ hideEmptyBox, emptyBoxVisible }">
        <WishlistEmptyBox v-if="!hideEmptyBox" :visible="emptyBoxVisible" />
      </template>
    </FilteredList>

    <PrimaryAction :label="$t('actions.addVehicle')" :action="showNewModal" />
  </section>
</template>

<script lang="ts">
import Vue from "vue";
import { Component, Watch } from "vue-property-decorator";
import { Getter, Action } from "vuex-class";
import FilteredList from "@/frontend/core/components/FilteredList/index.vue";
import FilteredGrid from "@/frontend/core/components/FilteredGrid/index.vue";
import VehiclesTable from "@/frontend/components/Vehicles/Table/index.vue";
import Btn from "@/frontend/core/components/Btn/index.vue";
import PrimaryAction from "@/frontend/core/components/PrimaryAction/index.vue";
import BtnDropdown from "@/frontend/core/components/BtnDropdown/index.vue";
import VehiclePanel from "@/frontend/components/Vehicles/Panel/index.vue";
import HangarImportBtn from "@/frontend/components/HangarImportBtn/index.vue";
import VehiclesFilterForm from "@/frontend/components/Vehicles/FilterForm/index.vue";
import ModelClassLabels from "@/frontend/components/Models/ClassLabels/index.vue";
import GroupLabels from "@/frontend/components/Vehicles/GroupLabels/index.vue";
import FleetchartApp from "@/frontend/components/Fleetchart/App/index.vue";
import AddonsModal from "@/frontend/components/Vehicles/AddonsModal/index.vue";
import ShareBtn from "@/frontend/components/ShareBtn/index.vue";
import { displayAlert, displayConfirm } from "@/frontend/lib/Noty";
import debounce from "lodash.debounce";
import { format } from "date-fns";
import wishlistCollection from "@/frontend/api/collections/Wishlist";
import type { WishlistCollection } from "@/frontend/api/collections/Wishlist";
import BreadCrumbs from "@/frontend/core/components/BreadCrumbs/index.vue";
import WishlistEmptyBox from "@/frontend/components/WishlistEmptyBox/index.vue";

@Component<Hangar>({
  components: {
    FilteredList,
    FilteredGrid,
    VehiclesTable,
    Btn,
    PrimaryAction,
    ShareBtn,
    BtnDropdown,
    HangarImportBtn,
    VehiclePanel,
    VehiclesFilterForm,
    ModelClassLabels,
    GroupLabels,
    AddonsModal,
    FleetchartApp,
    BreadCrumbs,
    WishlistEmptyBox,
  },
})
export default class Hangar extends Vue {
  deleting = false;

  vehiclesChannel = null;

  collection: WishlistCollection = wishlistCollection;

  @Getter("mobile") mobile;

  @Getter("currentUser", { namespace: "session" }) currentUser;

  @Getter("detailsVisible", { namespace: "wishlist" }) detailsVisible;

  @Getter("gridView", { namespace: "wishlist" }) gridView;

  @Getter("perPage", { namespace: "wishlist" }) perPage;

  @Action("toggleDetails", { namespace: "wishlist" }) toggleDetails;

  @Action("toggleGridView", { namespace: "wishlist" }) toggleGridView;

  get toggleDetailsTooltip() {
    if (this.detailsVisible) {
      return this.$t("actions.hideDetails");
    }
    return this.$t("actions.showDetails");
  }

  get toggleGridViewTooltip() {
    if (this.gridView) {
      return this.$t("actions.showTableView");
    }
    return this.$t("actions.showGridView");
  }

  get shareUrl() {
    if (!this.currentUser) {
      return null;
    }

    return this.currentUser.publicWishlistUrl;
  }

  get filters() {
    return {
      filters: this.$route.query.q,
      page: this.$route.query.page,
    };
  }

  @Watch("$route")
  onRouteChange() {
    this.fetch();
  }

  @Watch("perPage")
  onPerPageChange() {
    this.fetch();
  }

  mounted() {
    this.fetch();
    this.setupUpdates();
  }

  beforeDestroy() {
    if (this.vehiclesChannel) {
      this.vehiclesChannel.unsubscribe();
    }
  }

  showNewModal() {
    this.$comlink.$emit("open-modal", {
      component: () =>
        import("@/frontend/components/Vehicles/NewVehiclesModal/index.vue"),
      props: {
        wanted: true,
      },
    });
  }

  async fetch() {
    await this.collection.findAll(this.filters);
  }

  setupUpdates() {
    if (this.vehiclesChannel) {
      this.vehiclesChannel.unsubscribe();
    }

    this.vehiclesChannel = this.$cable.consumer.subscriptions.create(
      {
        channel: "WishlistChannel",
      },
      {
        received: debounce(this.fetch, 500),
      }
    );
  }

  async exportJson() {
    const exportedData = await this.collection.export(this.filters);

    // eslint-disable-next-line compat/compat
    if (!exportedData || !window.URL) {
      displayAlert({ text: this.$t("messages.wishlistExport.failure") });
      return;
    }

    const link = document.createElement("a");

    // eslint-disable-next-line compat/compat
    link.href = window.URL.createObjectURL(new Blob([exportedData]));

    link.setAttribute(
      "download",
      `fleetyards-${this.currentUser.username}-wishlist-${format(
        new Date(),
        "yyyy-MM-dd"
      )}.json`
    );

    document.body.appendChild(link);

    link.click();

    document.body.removeChild(link);
  }

  async destroyAll() {
    this.deleting = true;

    displayConfirm({
      text: this.$t("messages.confirm.wishlist.destroyAll"),
      onConfirm: async () => {
        await this.collection.destroyAll();

        this.$comlink.$emit("vehicles-delete-all");

        this.deleting = false;
      },
      onClose: () => {
        this.deleting = false;
      },
    });
  }
}
</script>
