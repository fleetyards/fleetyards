<script lang="ts">
export default {
  name: "VisualTestsChipsPage",
};
</script>

<script lang="ts" setup>
import Btn from "@/shared/components/base/Btn/index.vue";
import { BtnSizesEnum } from "@/shared/components/base/Btn/types";
import Chip from "@/shared/components/base/Chip/index.vue";
import ChipRow from "@/shared/components/base/Chip/Row/index.vue";
import Heading from "@/shared/components/base/Heading/index.vue";
import { HeadingLevelEnum } from "@/shared/components/base/Heading/types";
import { ChipStatesEnum } from "@/shared/components/base/Chip/types";

const states = [
  ChipStatesEnum.NEUTRAL,
  ChipStatesEnum.INCLUDED,
  ChipStatesEnum.EXCLUDED,
];

const groups = [
  { name: "Combat", color: "#dc3545", count: 12 },
  { name: "Exploration", color: "#428bca", count: 7 },
  { name: "Industrial", color: "#d4af37", count: 24 },
  { name: "Racing", color: "#5cb85c", count: 1 },
  { name: "A", color: "#7a8288", count: 1 },
];

// The tri-state cycle, live: the one behaviour a screenshot cannot show.
const cycled = ref<Record<string, ChipStatesEnum>>({});

const cycle = (name: string) => {
  const current = cycled.value[name] ?? ChipStatesEnum.NEUTRAL;

  if (current === ChipStatesEnum.NEUTRAL) {
    cycled.value[name] = ChipStatesEnum.INCLUDED;
  } else if (current === ChipStatesEnum.INCLUDED) {
    cycled.value[name] = ChipStatesEnum.EXCLUDED;
  } else {
    cycled.value[name] = ChipStatesEnum.NEUTRAL;
  }
};

const stateOf = (name: string) => cycled.value[name] ?? ChipStatesEnum.NEUTRAL;

const longRow = Array.from({ length: 18 }, (_, index) => ({
  name: `Classification ${index + 1}`,
  count: index * 3,
}));
</script>

<template>
  <Heading :level="HeadingLevelEnum.H2">States</Heading>
  <div class="row">
    <div class="col-12 vt-row">
      <Chip v-for="state in states" :key="state" :state="state">
        {{ state }}
      </Chip>
      <Chip disabled>disabled</Chip>
    </div>
  </div>

  <Heading :level="HeadingLevelEnum.H2">Dot, count and both</Heading>
  <div class="row">
    <div class="col-12 vt-row">
      <Chip dot="#428bca">Dot only</Chip>
      <Chip :count="42">Count only</Chip>
      <Chip dot="#5cb85c" :count="7">Dot and count</Chip>
      <Chip>Neither</Chip>
    </div>
  </div>

  <Heading :level="HeadingLevelEnum.H2">
    Narrow chips — the case fixed insets broke
  </Heading>
  <div class="row">
    <div class="col-12 vt-row">
      <Chip :count="1">A</Chip>
      <Chip dot="#dc3545" :count="1">B</Chip>
      <Chip>1</Chip>
      <Chip :state="ChipStatesEnum.INCLUDED">C</Chip>
      <Chip :state="ChipStatesEnum.EXCLUDED" :count="0">D</Chip>
    </div>
  </div>

  <Heading :level="HeadingLevelEnum.H2">
    The state carried by icon as well as tint
  </Heading>
  <div class="row">
    <div class="col-12 vt-row">
      <Chip
        v-for="group in groups"
        :key="`cycle-${group.name}`"
        :state="stateOf(group.name)"
        :dot="group.color"
        :count="group.count"
        @toggle="cycle(group.name)"
      >
        {{ group.name }}
      </Chip>
    </div>
  </div>

  <Heading :level="HeadingLevelEnum.H2">Editable — the group row</Heading>
  <div class="row">
    <div class="col-12">
      <ChipRow label="Groups">
        <Chip
          v-for="group in groups"
          :key="`editable-${group.name}`"
          :dot="group.color"
          :count="group.count"
          editable
          edit-label="Edit Group"
        >
          {{ group.name }}
        </Chip>
        <template #actions>
          <Btn :size="BtnSizesEnum.XS" aria-label="Add Group">
            <i class="fa-regular fa-plus" />
          </Btn>
        </template>
      </ChipRow>
    </div>
  </div>

  <Heading :level="HeadingLevelEnum.H2">Two rows, as the hangar has</Heading>
  <div class="row">
    <div class="col-12 vt-stack">
      <ChipRow label="Classifications">
        <Chip
          v-for="group in groups"
          :key="`row-a-${group.name}`"
          :count="group.count"
        >
          {{ group.name }}
        </Chip>
      </ChipRow>
      <ChipRow label="Groups">
        <Chip
          v-for="group in groups"
          :key="`row-b-${group.name}`"
          :dot="group.color"
          :count="group.count"
        >
          {{ group.name }}
        </Chip>
      </ChipRow>
    </div>
  </div>

  <Heading :level="HeadingLevelEnum.H2">Wrapping — a long row</Heading>
  <div class="row">
    <div class="col-12">
      <ChipRow label="Classifications">
        <Chip v-for="item in longRow" :key="item.name" :count="item.count">
          {{ item.name }}
        </Chip>
      </ChipRow>
    </div>
  </div>

  <Heading :level="HeadingLevelEnum.H2">
    Bare — a chip's contents inside another control
  </Heading>
  <div class="row">
    <div class="col-12 vt-row">
      <Btn
        v-for="state in states"
        :key="`bare-${state}`"
        :active="state === 'included'"
      >
        <Chip bare :state="state" dot="#428bca" :count="9">Menu item</Chip>
      </Btn>
    </div>
  </div>

  <Heading :level="HeadingLevelEnum.H2">In a narrow column</Heading>
  <div class="row">
    <div class="col-12 col-md-4">
      <ChipRow label="Groups">
        <Chip
          v-for="group in groups"
          :key="`narrow-${group.name}`"
          :dot="group.color"
          :count="group.count"
        >
          {{ group.name }}
        </Chip>
      </ChipRow>
    </div>
  </div>
</template>

<style lang="scss" scoped>
// The page spaces loose chips; Chip ships no margins of its own, as Btn does not.
.vt-row {
  display: flex;
  flex-wrap: wrap;
  align-items: center;
  gap: 10px;
  margin-bottom: 20px;
}

.vt-stack {
  display: flex;
  flex-direction: column;
  gap: 20px;
  margin-bottom: 20px;
}
</style>
