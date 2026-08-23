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
import { routes as visualTestsRoutes } from "@/frontend/pages/visual-tests/routes";

/*
 * AppConfirm and OffCanvas are singletons mounted once in App.vue and driven by
 * comlink events, so nothing here renders them - it asks the app to. That is
 * also why this page is the only place either is easy to look at: the confirm
 * only appears mid-action, and FilteredList opens the off-canvas on mobile
 * only, so on a desktop it is otherwise never on screen.
 */
const comlink = useComlink();

const log = ref<string[]>([]);

const record = (entry: string) => {
  log.value = [entry, ...log.value].slice(0, 6);
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
</script>

<template>
  <Heading :level="HeadingLevelEnum.H2">AppConfirm</Heading>
  <p>
    Mounted once in <code>App.vue</code> and shown by a
    <code>show-confirm</code> event, so there is nothing to render here. Enter
    confirms and Escape cancels, which is the part no screenshot shows.
  </p>
  <div class="row">
    <div class="col-12 vt-row">
      <Btn data-test="confirm-default" @click="confirmDefault">Default</Btn>
      <Btn data-test="confirm-custom" @click="confirmCustom">Custom texts</Btn>
      <Btn data-test="confirm-slow" @click="confirmSlow">Async handler</Btn>
      <Btn data-test="confirm-long" @click="confirmLong">Long question</Btn>
    </div>
  </div>
  <div class="row">
    <div class="col-12">
      <BaseText muted no-spacing>
        Handlers fired: {{ log.length ? log.join(" · ") : "—" }}
      </BaseText>
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
  <TabNavView :active-key="activeAnchor">
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
