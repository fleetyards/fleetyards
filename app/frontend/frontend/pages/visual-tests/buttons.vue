<script lang="ts">
export default {
  name: "VisualTestsButtonsPage",
};
</script>

<script lang="ts" setup>
import Btn from "@/shared/components/base/Btn/index.vue";
import BtnGroup from "@/shared/components/base/BtnGroup/index.vue";
import BtnConfirm from "@/shared/components/base/BtnConfirm/index.vue";
import PrimaryAction from "@/shared/components/PrimaryAction/index.vue";
import BtnDropdown from "@/shared/components/base/BtnDropdown/index.vue";
import {
  BtnSizesEnum,
  BtnTonesEnum,
  BtnVariantsEnum,
} from "@/shared/components/base/Btn/types";
import { HeadingLevelEnum } from "@/shared/components/base/Heading/types";

// PrimaryAction renders nothing without an `action`, and it is fixed-position, so
// the only way to tell it works is to mount it and count the clicks.
const primaryActionMounted = ref(false);
const primaryActionClicks = ref(0);

const primaryAction = () => {
  primaryActionClicks.value += 1;
};

const ships = ref(["Aegis Idris P", "Anvil Carrack", "Drake Cutlass Black"]);

const removed = ref<string[]>([]);

const removeShip = (name: string) => {
  ships.value = ships.value.filter((ship) => ship !== name);
  removed.value = [name, ...removed.value];
};

const restoreShips = () => {
  ships.value = ["Aegis Idris P", "Anvil Carrack", "Drake Cutlass Black"];
  removed.value = [];
};

const sizes = [
  BtnSizesEnum.XS,
  BtnSizesEnum.SM,
  BtnSizesEnum.MD,
  BtnSizesEnum.LG,
];
const variants = [
  BtnVariantsEnum.SOLID,
  BtnVariantsEnum.GHOST,
  BtnVariantsEnum.BARE,
];
const tones = [BtnTonesEnum.NEUTRAL, BtnTonesEnum.DANGER];

const loading = ref(false);
const active = ref<string | null>("grid");
const source = ref("game");
const view = ref("exterior");
const autoRotate = ref(true);
const zoom = ref(false);
const colour = ref(true);

const toggleLoading = () => {
  loading.value = !loading.value;
};
</script>

<template>
  <Heading :level="HeadingLevelEnum.H2">Variant × Tone</Heading>
  <div class="row">
    <div class="col-12 vt-row">
      <template v-for="tone in tones" :key="tone">
        <Btn
          v-for="variant in variants"
          :key="`${tone}-${variant}`"
          :variant="variant"
          :tone="tone"
        >
          {{ variant }} / {{ tone }}
        </Btn>
      </template>
    </div>
  </div>

  <Heading :level="HeadingLevelEnum.H2"
    >Sizes — end-caps at every width</Heading
  >
  <div class="row">
    <div class="col-12 vt-row">
      <Btn v-for="size in sizes" :key="size" :size="size">{{ size }}</Btn>
      <Btn size="sm">Buy</Btn>
      <Btn>Add to hangar</Btn>
      <Btn size="lg">Zur Zusammenstellungsübersicht hinzufügen</Btn>
    </div>
  </div>

  <Heading :level="HeadingLevelEnum.H2"
    >Icon only — the narrowest cap case</Heading
  >
  <div class="row">
    <div class="col-12 vt-row">
      <Btn
        v-for="size in sizes"
        :key="size"
        :size="size"
        aria-label="Sync hangar"
      >
        <i class="fa-solid fa-rotate" />
      </Btn>
      <Btn mobile-icon-only>
        <i class="fa-solid fa-rotate" />
        Icon only on mobile
      </Btn>
    </div>
  </div>

  <Heading :level="HeadingLevelEnum.H2">States</Heading>
  <div class="row">
    <div class="col-12 vt-row">
      <Btn>Rest</Btn>
      <Btn active>Active</Btn>
      <Btn disabled>Disabled</Btn>
      <Btn :loading="loading" spinner @click="toggleLoading">
        Toggle loading
      </Btn>
      <Btn :loading="loading" @click="toggleLoading">Loading, no spinner</Btn>
      <Btn confirm="Really?" @click="toggleLoading">With confirm</Btn>
    </div>
  </div>

  <Heading :level="HeadingLevelEnum.H2"
    >Links — disabled must not navigate</Heading
  >
  <div class="row">
    <div class="col-12 vt-row">
      <Btn href="https://fleetyards.net">External href</Btn>
      <Btn href="https://fleetyards.net" disabled>Disabled href</Btn>
      <Btn :to="{ name: 'visual-tests-buttons' }">Router link</Btn>
      <Btn :to="{ name: 'visual-tests-buttons' }" disabled>Disabled to</Btn>
    </div>
  </div>

  <Heading :level="HeadingLevelEnum.H2"
    >Group of toggles — independent, several can be on</Heading
  >
  <div class="row">
    <div class="col-12 vt-row">
      <!-- HoloViewer's case: not a switch. Any combination is valid, so there is
           no thumb to slide and each member carries its own on state. -->
      <BtnGroup>
        <Btn
          aria-label="Auto rotate"
          :active="autoRotate"
          @click="autoRotate = !autoRotate"
        >
          <i class="fa-light fa-planet-ringed" />
        </Btn>
        <Btn aria-label="Zoom" :active="zoom" @click="zoom = !zoom">
          <i class="fa-light fa-search-plus" />
        </Btn>
        <Btn aria-label="Colour" :active="colour" @click="colour = !colour">
          <i class="fa-light fa-palette" />
        </Btn>
      </BtnGroup>
    </div>
  </div>

  <Heading :level="HeadingLevelEnum.H2"
    >Segmented — a switch, not a row of actions</Heading
  >
  <div class="row">
    <div class="col-12 vt-row">
      <BtnGroup segmented>
        <Btn :active="source === 'game'" @click="source = 'game'">
          Game Files
        </Btn>
        <Btn :active="source === 'matrix'" @click="source = 'matrix'">
          Ship Matrix
        </Btn>
      </BtnGroup>
      <BtnGroup segmented>
        <Btn :active="view === 'exterior'" @click="view = 'exterior'">
          Exterior
        </Btn>
        <Btn :active="view === 'interior'" @click="view = 'interior'">
          Interior
        </Btn>
        <Btn :active="view === 'blueprint'" @click="view = 'blueprint'">
          Blueprint
        </Btn>
      </BtnGroup>
    </div>
  </div>

  <div class="row">
    <div class="col-12 vt-row">
      <BtnGroup segmented>
        <Btn :active="active === 'grid'" @click="active = 'grid'">Grid</Btn>
        <Btn :active="active === 'list'" @click="active = 'list'">List</Btn>
        <Btn :active="active === 'table'" @click="active = 'table'">Table</Btn>
      </BtnGroup>
      <BtnGroup :size="BtnSizesEnum.LG">
        <Btn>Large</Btn>
        <Btn>Group</Btn>
      </BtnGroup>
      <BtnGroup>
        <Btn aria-label="Grid"><i class="fa-solid fa-table-cells" /></Btn>
        <Btn aria-label="List"><i class="fa-solid fa-list" /></Btn>
      </BtnGroup>
    </div>
  </div>
  <Heading :level="HeadingLevelEnum.H2"
    >Group — container owns the chrome</Heading
  >
  <div class="row">
    <div class="col-12 vt-row" data-test="group-with-label">
      <!-- A group holding a plain label segment as well as buttons, the shape
           the paginator uses. The label must share the members' surface. -->
      <BtnGroup>
        <span>1 of 9</span>
        <Btn aria-label="Previous" disabled>
          <i class="fa-solid fa-chevron-left" />
        </Btn>
        <Btn aria-label="Next"><i class="fa-solid fa-chevron-right" /></Btn>
      </BtnGroup>
    </div>
  </div>
  <div class="row">
    <div class="col-12">
      <BtnGroup block>
        <Btn>Block</Btn>
        <Btn>group</Btn>
        <Btn>fills width</Btn>
      </BtnGroup>
    </div>
  </div>

  <Heading :level="HeadingLevelEnum.H2">PrimaryAction</Heading>
  <p>
    The floating action a page offers as its one obvious next step. It is
    fixed-position and renders nothing at all without an <code>action</code>, so
    it appears in the corner rather than here. On a real page the route's
    <code>meta.primaryAction</code> is what puts it there — and the environment
    pill shifts to make room for it.
  </p>
  <p class="text-muted">
    It is a <code>Btn</code>, so it is reachable from the keyboard and shows a
    focus ring. It used to be a <code>div</code> with a click handler in a
    circle, which meant the hangar's primary action could not be tabbed to at
    all.
  </p>
  <div class="row">
    <div class="col-12 vt-row">
      <Btn
        :active="primaryActionMounted"
        data-test="toggle-primary-action"
        @click="primaryActionMounted = !primaryActionMounted"
      >
        {{ primaryActionMounted ? "Remove it" : "Show it" }}
      </Btn>
      <span data-test="primary-action-clicks">
        Clicked {{ primaryActionClicks }}×
      </span>
    </div>
  </div>
  <PrimaryAction
    v-if="primaryActionMounted"
    :action="primaryAction"
    label="Add a ship"
  />

  <Heading :level="HeadingLevelEnum.H2">Inline confirm</Heading>
  <p>
    Asks where the action is, for the decisions a modal is too heavy for. Armed,
    the trigger is replaced by a group holding the question and two actions —
    the same shape as the paginator above, so the three segments read as one
    control.
  </p>
  <p>
    <code>Escape</code> disarms, a click anywhere outside disarms, and arming a
    second row disarms the first: two open questions in one list is an
    invitation to answer the wrong one.
  </p>
  <div class="row">
    <div class="col-12">
      <div
        v-for="ship in ships"
        :key="ship"
        class="vt-row"
        :data-test="`ship-row-${ship}`"
      >
        <span class="vt-row__name">{{ ship }}</span>
        <BtnConfirm question="Remove?" @confirm="removeShip(ship)">
          Remove
        </BtnConfirm>
      </div>
    </div>
  </div>
  <div class="row">
    <div class="col-12 vt-row">
      <BtnConfirm
        :size="BtnSizesEnum.SM"
        question="Delete?"
        confirm-text="Delete"
        cancel-text="Keep"
      >
        Small, custom labels
      </BtnConfirm>
      <BtnConfirm data-test="confirm-narrow" hide-question>
        Too narrow for a question
      </BtnConfirm>
      <BtnConfirm data-test="confirm-disabled" disabled>Disabled</BtnConfirm>
      <Btn data-test="restore-ships" @click="restoreShips">Restore</Btn>
    </div>
  </div>
  <div class="row">
    <div class="col-12">
      <p class="text-muted" data-test="removed-log">
        Removed: {{ removed.length ? removed.join(", ") : "—" }}
      </p>
    </div>
  </div>

  <Heading :level="HeadingLevelEnum.H2">Dropdown</Heading>
  <div class="row">
    <div class="col-12 vt-row">
      <BtnDropdown>
        <Btn>First action</Btn>
        <Btn>Second action</Btn>
        <hr />
        <Btn :tone="BtnTonesEnum.DANGER">Destructive action</Btn>
      </BtnDropdown>
      <BtnDropdown expand-bottom>
        <template #label>With a label</template>
        <Btn>Menu item</Btn>
        <Btn>Another item</Btn>
      </BtnDropdown>
      <BtnGroup>
        <Btn>Grouped</Btn>
        <BtnDropdown />
      </BtnGroup>
    </div>
  </div>

  <Heading :level="HeadingLevelEnum.H2">Block</Heading>
  <div class="row">
    <div class="col-12">
      <Btn block>Block button</Btn>
    </div>
  </div>
</template>

<style lang="scss" scoped>
// Loose buttons are spaced by the shared .vt-row on visual-tests.vue; Btn ships
// no margins of its own. Only the list rows need anything of their own: a name
// column wide enough that the confirm does not shift sideways when it arms.
.vt-row__name {
  min-width: 12rem;
}
</style>
