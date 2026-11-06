import { type ShipListState } from "@/frontend/types";
import { renameTableCols } from "@/frontend/utils/renamedTableCols";
import { ModelStateEnum } from "@/frontend/composables/useModelStates";
import { defineStore } from "pinia";

export enum ModelTableViewImageColsEnum {
  STORE_IMAGE = "storeImage",
  STORE_IMAGE_WIDE = "storeImageWide",
  ANGLED_VIEW = "angledView",
  ANGLED_VIEW_WIDE = "angledViewWide",
}

export enum ModelTableViewColsEnum {
  MANUFACTURER_NAME = "manufacturerName",
  LENGTH = "length",
  BEAM = "beam",
  HEIGHT = "height",
  MASS = "mass",
  CARGO = "cargo",
  QUANTUM_FUEL = "quantumFuelTankSize",
  HYDROGEN_FUEL = "hydrogenFuelTankSize",
  CREW = "crew",
  SCM_SPEED = "scmSpeed",
  MAX_SPEED = "maxSpeed",
  GROUND_MAX_SPEED = "groundMaxSpeed",
  FOCUS = "focus",
  PRODUCTION_STATUS = "productionStatus",
  PRICE = "price",
  PLEDGE_PRICE = "pledgePrice",
}

// Every sort the ships list can offer as a chip. Crew and fuel have columns
// but no sort: the server does not order by them.
export enum ModelSortFieldsEnum {
  NAME = "name",
  MANUFACTURER_NAME = "manufacturerName",
  LENGTH = "length",
  BEAM = "beam",
  HEIGHT = "height",
  MASS = "mass",
  CARGO = "cargo",
  SCM_SPEED = "scmSpeed",
  MAX_SPEED = "maxSpeed",
  GROUND_MAX_SPEED = "groundMaxSpeed",
  PRODUCTION_STATUS = "productionStatus",
  PRICE = "price",
  PLEDGE_PRICE = "pledgePrice",
}

interface ModelsState extends ShipListState {
  holoviewerVisible: boolean;
  // The ship page's full metrics cards, rather than the row of key figures.
  shipMetricsAdvanced: boolean;
  // The hardpoint cards a reader flipped from how they open, by ship or loadout.
  // Only the exceptions are kept, and what a card opens as is the section's call.
  flippedHardpointGroups: Record<string, string[]>;
  // The sections a reader closed, by model slug or loadout and then anchor.
  collapsedSections: Record<string, string[]>;
  modelState: ModelStateEnum;
  tableViewCols: ModelTableViewColsEnum[];
  tableViewImageCols: ModelTableViewImageColsEnum[];
  sortFields: ModelSortFieldsEnum[];
}

export const useModelsStore = defineStore("models", {
  state: (): ModelsState => ({
    holoviewerVisible: false,
    shipMetricsAdvanced: false,
    flippedHardpointGroups: {},
    collapsedSections: {},
    modelState: ModelStateEnum.FLIGHT,
    detailsVisible: false,
    filterVisible: true,
    gridView: true,
    tableViewImageCols: [
      ModelTableViewImageColsEnum.STORE_IMAGE,
      ModelTableViewImageColsEnum.ANGLED_VIEW,
    ],
    tableViewCols: [
      ModelTableViewColsEnum.LENGTH,
      ModelTableViewColsEnum.BEAM,
      ModelTableViewColsEnum.HEIGHT,
      ModelTableViewColsEnum.MASS,
      ModelTableViewColsEnum.CARGO,
      ModelTableViewColsEnum.CREW,
    ],
    sortFields: [
      ModelSortFieldsEnum.NAME,
      ModelSortFieldsEnum.MANUFACTURER_NAME,
      ModelSortFieldsEnum.LENGTH,
      ModelSortFieldsEnum.CARGO,
      ModelSortFieldsEnum.PRICE,
      ModelSortFieldsEnum.PRODUCTION_STATUS,
    ],
  }),
  getters: {
    hardpointGroupFlipped(state) {
      return (modelSlug: string, group: string) =>
        !!state.flippedHardpointGroups[modelSlug]?.includes(group);
    },
    sectionCollapsed(state) {
      return (modelSlug: string, section: string) =>
        !!state.collapsedSections[modelSlug]?.includes(section);
    },
  },
  actions: {
    toggleHoloviewer() {
      this.holoviewerVisible = !this.holoviewerVisible;
    },
    toggleShipMetricsAdvanced() {
      this.shipMetricsAdvanced = !this.shipMetricsAdvanced;
    },
    setFlippedHardpointGroups(modelSlug: string, groups: string[]) {
      const { [modelSlug]: _removed, ...others } = this.flippedHardpointGroups;

      this.flippedHardpointGroups = groups.length
        ? { ...others, [modelSlug]: groups }
        : others;
    },
    toggleHardpointGroup(modelSlug: string, group: string) {
      const groups = this.flippedHardpointGroups[modelSlug] || [];

      this.setFlippedHardpointGroups(
        modelSlug,
        groups.includes(group)
          ? groups.filter((name) => name !== group)
          : [...groups, group],
      );
    },
    toggleSection(modelSlug: string, section: string) {
      if (this.sectionCollapsed(modelSlug, section)) {
        this.expandSection(modelSlug, section);
        return;
      }

      this.collapsedSections = {
        ...this.collapsedSections,
        [modelSlug]: [...(this.collapsedSections[modelSlug] || []), section],
      };
    },
    expandSection(modelSlug: string, section: string) {
      const remaining = (this.collapsedSections[modelSlug] || []).filter(
        (name) => name !== section,
      );
      const { [modelSlug]: _removed, ...others } = this.collapsedSections;

      // A model with every section open drops out of the map, so it does not
      // grow by a key for each ship a reader has ever opened.
      this.collapsedSections = remaining.length
        ? { ...others, [modelSlug]: remaining }
        : others;
    },
    // One selection for the whole session: a visitor who wants ships landed
    // wants the next ship landed too, where it has the images for it.
    setModelState(state: ModelStateEnum) {
      this.modelState = state;
    },
    toggleDetails() {
      this.detailsVisible = !this.detailsVisible;
    },
    toggleGridView() {
      this.gridView = !this.gridView;
    },
    toggleFilter() {
      this.filterVisible = !this.filterVisible;
    },
    setTableViewCols(cols: ModelTableViewColsEnum[]) {
      this.tableViewCols = cols;
    },
    setTableViewImageCols(cols: ModelTableViewImageColsEnum[]) {
      this.tableViewImageCols = cols;
    },
    setSortFields(fields: ModelSortFieldsEnum[]) {
      this.sortFields = fields;
    },
  },
  persist: {
    pick: [
      "holoviewerVisible",
      "shipMetricsAdvanced",
      "flippedHardpointGroups",
      "collapsedSections",
      "modelState",
      "detailsVisible",
      "gridView",
      "tableViewCols",
      "tableViewImageCols",
      "sortFields",
    ],
    afterHydrate: ({ store }) => {
      store.tableViewCols = renameTableCols<ModelTableViewColsEnum>(
        store.tableViewCols,
        {
          minCrew: ModelTableViewColsEnum.CREW,
          maxCrew: ModelTableViewColsEnum.CREW,
        },
      );
    },
  },
});
