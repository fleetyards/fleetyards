<script lang="ts">
export default {
  name: "VisualTestsOverlaysPage",
};
</script>

<script lang="ts" setup>
import Btn from "@/shared/components/base/Btn/index.vue";
import Heading from "@/shared/components/base/Heading/index.vue";
import BaseText from "@/shared/components/base/Text/index.vue";
import BreadCrumbs from "@/shared/components/BreadCrumbs/index.vue";
import TabNavView from "@/shared/components/TabNavView/index.vue";
import TabNavViewAnchorItems from "@/shared/components/TabNavView/AnchorItems/index.vue";
import Panel from "@/shared/components/base/Panel/index.vue";
import PanelBody from "@/shared/components/base/Panel/Body/index.vue";
import { HeadingLevelEnum } from "@/shared/components/base/Heading/types";
import { useComlink } from "@/shared/composables/useComlink";
import { AppConfirmTonesEnum } from "@/shared/components/AppConfirm/types";
import { routes as visualTestsRoutes } from "@/frontend/pages/visual-tests/routes";
import BasePopover from "@/shared/components/Popover/index.vue";
import CatalogueItemPopover from "@/frontend/components/CatalogueItemPopover/index.vue";
import ComponentStatsCard from "@/frontend/components/StatsCard/Component/index.vue";
import ShipStatsCard from "@/frontend/components/StatsCard/Ship/index.vue";
import storeImage from "@/images/fallback/store_image.webp";
import {
  EquipmentTypeEnum,
  type Blueprint,
  type Commodity,
  type Component,
  type Equipment,
  type GameMission,
  type Location,
  LocationKindEnum,
  type Model,
} from "@/services/fyApi";

/*
 * AppConfirm and OffCanvas are singletons mounted once in App.vue and driven by
 * comlink events, so nothing here renders them - it asks the app to. That is
 * also why this page is the only place either is easy to look at: the confirm
 * only appears mid-action, and FilteredList opens the off-canvas on mobile
 * only, so on a desktop it is otherwise never on screen.
 */
const comlink = useComlink();

const log = ref<string[]>([]);

// One list item per outcome, each with its own hook: a joined string cannot be
// asserted against precisely, which quietly made "cancel did not run" trivially
// true in a test.
const record = (entry: string) => {
  log.value = [entry, ...log.value.filter((seen) => seen !== entry)].slice(
    0,
    6,
  );
};

const confirmDefault = () => {
  comlink.emit("show-confirm", {
    onConfirm: () => record("confirmed (default text)"),
    onClose: () => record("cancelled"),
  });
};

const confirmCustom = () => {
  comlink.emit("show-confirm", {
    text: "Delete the Idris P from your hangar? This cannot be undone.",
    confirmText: "Delete it",
    cancelText: "Keep it",
    onConfirm: () => record("confirmed (custom text)"),
    onClose: () => record("cancelled (custom text)"),
  });
};

// An async handler is the case worth having on screen: the dialog has to stay
// put until the promise settles, rather than closing and leaving no feedback.
const confirmSlow = () => {
  comlink.emit("show-confirm", {
    text: "This one takes two seconds to confirm.",
    confirmText: "Take your time",
    onConfirm: async () => {
      record("slow confirm started");
      await new Promise((resolve) => setTimeout(resolve, 2000));
      record("slow confirm finished");
    },
  });
};

const confirmDestructive = () => {
  comlink.emit("show-confirm", {
    text: "Delete all 284 ships from your hangar?",
    confirmText: "Delete everything",
    tone: AppConfirmTonesEnum.DANGER,
    onConfirm: () => record("confirmed (danger tone)"),
  });
};

const confirmWarning = () => {
  comlink.emit("show-confirm", {
    text: "Reload the ship matrix? This runs for a while and cannot be stopped.",
    confirmText: "Reload",
    tone: AppConfirmTonesEnum.WARNING,
    onConfirm: () => record("confirmed (warning tone)"),
  });
};

const confirmLong = () => {
  comlink.emit("show-confirm", {
    text: "A much longer question, of the kind a destructive action deserves, so the box has to wrap it rather than stretch across the viewport. Reticulating-splines-with-no-space-to-break-on-0000000000.",
    onConfirm: () => record("confirmed (long text)"),
  });
};

const openOffCanvas = (side: "left" | "right", title?: string) => {
  comlink.emit("open-off-canvas", { title, side });
};

const closeOffCanvas = () => {
  comlink.emit("close-off-canvas");
};

const crumbsShort = [
  { to: { name: "home" }, label: "Home" },
  { label: "Ships" },
];

const crumbsLong = [
  { to: { name: "home" }, label: "Home" },
  { to: { name: "visual-tests-panels" }, label: "Visual Tests" },
  { to: { name: "visual-tests-overlays" }, label: "Overlays" },
  { label: "A trailing crumb with a considerably longer label than the rest" },
];

// The routes mode reads `nav.<meta.title>` for each label, and the visual-tests
// routes carry exactly those keys, so it can be fed the real thing.
const tabRoutes = computed(() => visualTestsRoutes.slice(0, 5));

const anchorItems = [
  { id: "clean", label: "Clean", disabled: false, invalid: false },
  { id: "invalid", label: "With errors", disabled: false, invalid: true },
  { id: "locked", label: "Disabled", disabled: true, invalid: false },
];

const activeAnchor = ref("clean");

// Fixtures rather than a fetch, so the cards render without a backend.
const demoCooler = {
  id: "demo-cooler",
  name: "Glacier",
  slug: "glacier",
  catalogued: true,
  category: "cooler",
  size: 2,
  gradeLabel: "A",
  itemClassLabel: "Military",
  manufacturer: { name: "J-Span" },
  typeData: {
    coolingRate: 1250000,
    powerConsumption: 3,
    signatureEm: 1500,
    signatureIr: 4200,
  },
} as unknown as Component;

const demoArmor = {
  id: "demo-armor",
  name: "Morozov-SH Core",
  slug: "morozov-sh-core",
  equipmentType: EquipmentTypeEnum.ARMOR,
  equipmentTypeLabel: "Armor",
  slotLabel: "Core",
  grade: "B",
  manufacturer: { name: "Roussimoff Rehabilitation Systems" },
  damageReduction: 30,
  temperatureRating: "-65 / 95 °C",
  radiationProtection: 12000,
  volume: 0.035,
} as unknown as Equipment;

const demoCommodity = {
  id: "demo-commodity",
  name: "Agricium",
  slug: "agricium",
  commodityType: "metal",
  containerSizes: [1, 2, 4, 8, 16, 24, 32],
  consumable: false,
  counted: false,
  sellPrice: 2640,
  buyPrice: 2410,
} as unknown as Commodity;

const demoShip = {
  id: "demo-ship",
  name: "Carrack",
  slug: "carrack",
  classificationLabel: "Exploration",
  productionStatus: "flight-ready",
  pledgePriceLabel: "$600",
  crew: { value: 6, label: "6" },
  manufacturer: { name: "Anvil Aerospace" },
  media: { storeImage: { smallUrl: storeImage } },
} as unknown as Model;

const demoBlueprint = {
  id: "demo-blueprint",
  name: "Glacier",
  slug: "glacier-blueprint",
  craftTime: 960,
  slotCount: 3,
  retired: false,
  craftable: {
    type: "Component",
    name: "Glacier",
    slug: "glacier",
    listed: true,
  },
  materials: [
    { id: "iron", name: "Iron", slug: "iron" },
    { id: "titanium", name: "Titanium", slug: "titanium" },
  ],
} as unknown as Blueprint;

const demoMission = {
  id: "demo-mission",
  name: "A Challenging Contract",
  slug: "a-challenging-contract",
  kind: "career",
  org: { name: "Vaughn" },
  retired: false,
  released: false,
} as unknown as GameMission;

const demoLocation = {
  id: "demo-location",
  name: "Lorville",
  slug: "lorville",
  kind: LocationKindEnum.CITY,
  description:
    "Hurston Dynamics' company town, under a sky the factories keep orange.",
  quantumTravelDestination: true,
  childrenCount: 4,
  retired: false,
  image: { url: storeImage, mediumUrl: storeImage },
  ancestors: [
    {
      id: "demo-stanton",
      name: "Stanton System",
      slug: "stanton-system",
      kind: LocationKindEnum.SYSTEM,
      parentName: null,
    },
    {
      id: "demo-hurston",
      name: "Hurston",
      slug: "hurston",
      kind: LocationKindEnum.PLANET,
      parentName: "Stanton",
    },
  ],
} as unknown as Location;

// A planet is drawn as its turning globe, a star as its sun.
const demoPlanet = {
  ...demoLocation,
  id: "demo-planet",
  name: "Hurston",
  slug: "hurston",
  kind: LocationKindEnum.PLANET,
  color: "#9c846e",
  image: undefined,
  description: "A world strip-mined by the company that owns it.",
  ancestors: demoLocation.ancestors?.slice(0, 1),
} as unknown as Location;

const demoStar = {
  ...demoPlanet,
  id: "demo-star",
  name: "Pyro",
  slug: "pyro",
  kind: LocationKindEnum.STAR,
  color: "#ffb066",
  unstable: true,
  description: "A K-type main sequence flare star.",
  ancestors: [
    {
      id: "demo-pyro-system",
      name: "Pyro System",
      slug: "pyro-system",
      kind: LocationKindEnum.SYSTEM,
      parentName: null,
    },
  ],
} as unknown as Location;
</script>

<template>
  <Heading :level="HeadingLevelEnum.H2">AppConfirm</Heading>
  <p>
    Mounted once in <code>App.vue</code> and shown by a
    <code>show-confirm</code> event, so there is nothing to render here. The
    confirming button holds focus, so Enter activates it natively; Escape and
    the backdrop cancel.
  </p>
  <p class="text-muted">
    Three tones, and <code>neutral</code> is the default: most confirmations are
    not emergencies, and colour on every one of them stops meaning anything.
    <code>warning</code> is for what cannot simply be repeated,
    <code>danger</code> for what does not come back — and only
    <code>danger</code> tones the confirming button, because a warning dressed
    as a danger stops being read.
  </p>
  <div class="row">
    <div class="col-12 vt-row">
      <Btn data-test="confirm-default" @click="confirmDefault">Default</Btn>
      <Btn data-test="confirm-custom" @click="confirmCustom">Custom texts</Btn>
      <Btn data-test="confirm-slow" @click="confirmSlow">Async handler</Btn>
      <Btn data-test="confirm-long" @click="confirmLong">Long question</Btn>
      <Btn data-test="confirm-warning" @click="confirmWarning">
        Warning tone
      </Btn>
      <Btn data-test="confirm-destructive" @click="confirmDestructive">
        Danger tone
      </Btn>
    </div>
  </div>
  <div class="row">
    <div class="col-12">
      <BaseText muted no-spacing>Handlers fired:</BaseText>
      <ul data-test="confirm-log">
        <li v-for="entry in log" :key="entry" :data-test="`fired-${entry}`">
          {{ entry }}
        </li>
        <li v-if="!log.length">—</li>
      </ul>
    </div>
  </div>

  <Heading :level="HeadingLevelEnum.H2">OffCanvas</Heading>
  <p>
    Also a singleton, and also comlink-driven. It renders an empty container and
    whoever wants to fill it teleports into
    <code>#off-canvas-content</code> — the panel below is teleported from this
    page. In the app <code>FilteredList</code> only opens it on mobile, so this
    is the one place to see it at desktop width.
  </p>
  <p class="text-muted">
    There is no close button out here on purpose: the backdrop covers the page
    while the panel is open, so nothing behind it can be clicked. Close it from
    inside the panel, or by clicking the backdrop.
  </p>
  <div class="row">
    <div class="col-12 vt-row">
      <Btn
        data-test="off-canvas-left"
        @click="openOffCanvas('left', 'Filters')"
      >
        Open left
      </Btn>
      <Btn
        data-test="off-canvas-right"
        @click="openOffCanvas('right', 'Details')"
      >
        Open right
      </Btn>
      <Btn data-test="off-canvas-untitled" @click="openOffCanvas('left')">
        Open without a title
      </Btn>
    </div>
  </div>

  <Teleport to="#off-canvas-content">
    <div data-test="off-canvas-demo-content">
      <BaseText>Teleported from the overlays demo.</BaseText>
      <Btn data-test="off-canvas-inner-close" @click="closeOffCanvas">
        Close from inside
      </Btn>
    </div>
  </Teleport>

  <Heading :level="HeadingLevelEnum.H2">Popover</Heading>
  <p>
    Hover a name with a mouse, or focus it with the keyboard, and its stats card
    opens after a short delay; the pointer can cross into the card. On touch the
    first tap opens the card instead of following the link, and a tap outside,
    Escape or a scroll closes it. Each of these carries its record, so nothing
    is fetched; the armour has no page link here and is focusable on its own.
    The last two stay loading, to show the skeleton and the loading line; a
    ship's also holds its image's height.
  </p>
  <div class="row">
    <div class="col-12 vt-row">
      <span data-test="popover-demo-component">
        <CatalogueItemPopover
          :item="{ type: 'Component', slug: 'glacier', name: 'Glacier' }"
          :record="demoCooler"
        />
      </span>
      <span data-test="popover-demo-equipment">
        <CatalogueItemPopover
          :item="{ type: 'Equipment', name: demoArmor.name, listed: false }"
          :record="demoArmor"
        />
      </span>
      <span data-test="popover-demo-commodity">
        <CatalogueItemPopover
          :item="{ type: 'Commodity', slug: 'agricium', name: 'Agricium' }"
          :record="demoCommodity"
        />
      </span>
      <span data-test="popover-demo-ship">
        <CatalogueItemPopover
          :item="{ type: 'Model', slug: 'carrack', name: 'Carrack' }"
          :record="demoShip"
        />
      </span>
      <span data-test="popover-demo-blueprint">
        <CatalogueItemPopover
          :item="{
            type: 'Blueprint',
            slug: 'glacier-blueprint',
            name: 'Glacier',
          }"
          :record="demoBlueprint"
        />
      </span>
      <span data-test="popover-demo-mission">
        <CatalogueItemPopover
          :item="{
            type: 'GameMission',
            slug: 'a-challenging-contract',
            name: 'A Challenging Contract',
          }"
          :record="demoMission"
        />
      </span>
      <span data-test="popover-demo-location">
        <CatalogueItemPopover
          :item="{ type: 'Location', slug: 'lorville', name: 'Lorville' }"
          :record="demoLocation"
        />
      </span>
      <span data-test="popover-demo-planet">
        <CatalogueItemPopover
          :item="{ type: 'Location', slug: 'hurston', name: 'Hurston' }"
          :record="demoPlanet"
        />
      </span>
      <span data-test="popover-demo-star">
        <CatalogueItemPopover
          :item="{ type: 'Location', slug: 'pyro', name: 'Pyro' }"
          :record="demoStar"
        />
      </span>
      <BasePopover label="Loading" data-test="popover-demo-loading">
        <a href="#popover">Still loading</a>
        <template #content>
          <ComponentStatsCard compact loading name="Glacier" />
        </template>
      </BasePopover>
      <BasePopover label="Loading a ship" data-test="popover-demo-ship-loading">
        <a href="#popover">Ship still loading</a>
        <template #content>
          <ShipStatsCard loading name="Carrack" />
        </template>
      </BasePopover>
    </div>
  </div>

  <Heading :level="HeadingLevelEnum.H2">BreadCrumbs</Heading>
  <p>
    A crumb without a <code>to</code> is the current page and is not a link. The
    admin stepper mode is not shown here: it points at
    <code>admin-model-edit</code>, a route this app does not have.
  </p>
  <div class="row">
    <div class="col-12">
      <BreadCrumbs :crumbs="crumbsShort" />
    </div>
  </div>
  <div class="row">
    <div class="col-12">
      <BreadCrumbs :crumbs="crumbsLong" />
    </div>
  </div>
  <div class="row">
    <div class="col-6">
      <BaseText muted no-spacing>In a narrow column</BaseText>
      <BreadCrumbs :crumbs="crumbsLong" />
    </div>
  </div>

  <Heading :level="HeadingLevelEnum.H2">TabNavView | From routes</Heading>
  <p>
    Fed the first five visual-tests routes. Each label comes from
    <code>nav.&lt;meta.title&gt;</code>, and the tab matching the current route
    is marked active. Below the <code>md</code> breakpoint the list becomes a
    dropdown instead.
  </p>
  <TabNavView :routes="tabRoutes">
    <template #content>
      <Panel>
        <PanelBody>
          <BaseText no-spacing>
            The content slot. Without one this renders a
            <code>router-view</code>, which is how the settings pages use it.
          </BaseText>
        </PanelBody>
      </Panel>
    </template>
  </TabNavView>

  <Heading :level="HeadingLevelEnum.H2">TabNavView | From items</Heading>
  <p>
    The slot form, which is what <code>FormTabs</code> builds on: ids rather
    than routes, and a tab can be marked invalid or disabled.
  </p>
  <TabNavView tablist :active-key="activeAnchor">
    <template #nav>
      <TabNavViewAnchorItems
        :items="anchorItems"
        :active-id="activeAnchor"
        @update:active-id="activeAnchor = $event"
      />
    </template>
    <template #content>
      <Panel>
        <PanelBody>
          <BaseText no-spacing>Active: {{ activeAnchor }}</BaseText>
        </PanelBody>
      </Panel>
    </template>
  </TabNavView>
</template>
