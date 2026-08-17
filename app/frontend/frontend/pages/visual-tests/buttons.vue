<script lang="ts">
export default {
  name: "VisualTestsButtonsPage",
};
</script>

<script lang="ts" setup>
import Btn from "@/shared/components/base/Btn/index.vue";
import BtnGroup from "@/shared/components/base/BtnGroup/index.vue";
import BtnDropdown from "@/shared/components/base/BtnDropdown/index.vue";
import {
  BtnSizesEnum,
  BtnTonesEnum,
  BtnVariantsEnum,
} from "@/shared/components/base/Btn/types";
import { HeadingLevelEnum } from "@/shared/components/base/Heading/types";

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
    >Group — container owns the chrome</Heading
  >
  <Heading :level="HeadingLevelEnum.H2"
    >Segmented — a switch, not a row of actions</Heading
  >
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
// The page is the only place that needs to space loose buttons; Btn ships no
// margins of its own.
.vt-row {
  display: flex;
  flex-wrap: wrap;
  align-items: center;
  gap: 10px;
  margin-bottom: 20px;
}
</style>
