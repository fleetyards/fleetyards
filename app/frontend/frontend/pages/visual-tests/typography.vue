<script lang="ts">
export default {
  name: "VisualTestsTypographyPage",
};
</script>

<script lang="ts" setup>
import BaseGrid from "@/shared/components/base/Grid/index.vue";
import BasePill from "@/shared/components/base/Pill/index.vue";
import BaseText from "@/shared/components/base/Text/index.vue";
import Box from "@/shared/components/Box/index.vue";
import Heading from "@/shared/components/base/Heading/index.vue";
import Panel from "@/shared/components/base/Panel/index.vue";
import PanelBody from "@/shared/components/base/Panel/Body/index.vue";
import Spacer from "@/shared/components/base/Spacer/index.vue";
import {
  HeadingAlignmentEnum,
  HeadingLevelEnum,
  HeadingSizeEnum,
} from "@/shared/components/base/Heading/types";
import { PanelVariantsEnum } from "@/shared/components/base/Panel/types";

const headingSizes = [
  HeadingSizeEnum.LG,
  HeadingSizeEnum.XL,
  HeadingSizeEnum.XXL,
  HeadingSizeEnum.HERO_SM,
  HeadingSizeEnum.HERO,
];

const headingLevels = [
  HeadingLevelEnum.H1,
  HeadingLevelEnum.H2,
  HeadingLevelEnum.H3,
  HeadingLevelEnum.H4,
];

const headingAlignments = [
  HeadingAlignmentEnum.LEFT,
  HeadingAlignmentEnum.CENTER,
  HeadingAlignmentEnum.RIGHT,
];

const pillVariants = ["default", "success", "warning", "danger"] as const;

const gridRecords = [
  { id: "1", name: "Galaxy", manufacturer: "RSI" },
  { id: "2", name: "Carrack", manufacturer: "Anvil" },
  { id: "3", name: "Corsair", manufacturer: "Drake" },
  { id: "4", name: "Zeus Mk II", manufacturer: "RSI" },
  { id: "5", name: "Polaris", manufacturer: "RSI" },
  { id: "6", name: "Perseus", manufacturer: "RSI" },
];
</script>

<template>
  <Heading :level="HeadingLevelEnum.H2">Heading | Sizes</Heading>
  <p>
    Each size in the hero face (Orbitron) and the body face (Open Sans). The
    <code>hero</code> flag picks the face; <code>size</code> is independent of
    the semantic <code>level</code>.
  </p>
  <div class="row">
    <div class="col-12 col-lg-6">
      <Heading
        v-for="size in headingSizes"
        :key="`hero-${size}`"
        :level="HeadingLevelEnum.H3"
        :size="size"
        hero
      >
        Hero / {{ size }}
      </Heading>
    </div>
    <div class="col-12 col-lg-6">
      <Heading
        v-for="size in headingSizes"
        :key="`sans-${size}`"
        :level="HeadingLevelEnum.H3"
        :size="size"
      >
        Open Sans / {{ size }}
      </Heading>
    </div>
  </div>

  <Heading :level="HeadingLevelEnum.H2">Heading | Levels</Heading>
  <p>
    Semantic levels at a fixed size — the tag changes, the rendering does not.
  </p>
  <div class="row">
    <div class="col-12">
      <Heading
        v-for="level in headingLevels"
        :key="`level-${level}`"
        :level="level"
        :size="HeadingSizeEnum.XL"
      >
        {{ level }}
      </Heading>
    </div>
  </div>

  <Heading :level="HeadingLevelEnum.H2">Heading | Alignment</Heading>
  <p>Left, center and right, with and without an inline sub heading.</p>
  <div class="row">
    <div class="col-12 col-lg-6">
      <Heading
        v-for="alignment in headingAlignments"
        :key="`stacked-${alignment}`"
        :level="HeadingLevelEnum.H3"
        :size="HeadingSizeEnum.XL"
        :alignment="alignment"
      >
        {{ alignment }}
        <template #subHeading>stacked sub heading</template>
      </Heading>
    </div>
    <div class="col-12 col-lg-6">
      <Heading
        v-for="alignment in headingAlignments"
        :key="`inline-${alignment}`"
        :level="HeadingLevelEnum.H3"
        :size="HeadingSizeEnum.XL"
        :alignment="alignment"
        inline-sub-heading
      >
        {{ alignment }}
        <template #subHeading>inline sub heading</template>
      </Heading>
    </div>
  </div>

  <Heading :level="HeadingLevelEnum.H2">Heading | Modifiers</Heading>
  <p>
    Text shadow, truncation, and the margin helpers. There is also
    <code>hidden</code>, which renders screen-reader-only — nothing visible
    should appear for it.
  </p>
  <div class="row">
    <div class="col-12 col-lg-6">
      <Heading :level="HeadingLevelEnum.H3" :size="HeadingSizeEnum.XL" shadow>
        With text shadow
      </Heading>
      <Heading :level="HeadingLevelEnum.H3" :size="HeadingSizeEnum.XL" mt mb>
        With top and bottom margin
      </Heading>
      <Heading :level="HeadingLevelEnum.H3" :size="HeadingSizeEnum.XL" hidden>
        Screen reader only
      </Heading>
    </div>
    <div class="col-12 col-lg-3">
      <Heading :level="HeadingLevelEnum.H3" :size="HeadingSizeEnum.XL" truncate>
        A heading long enough that it has to be truncated in this column
      </Heading>
    </div>
  </div>

  <Heading :level="HeadingLevelEnum.H2">Text</Heading>
  <p>Body copy, muted, without spacing, and as a span or div.</p>
  <div class="row">
    <div class="col-12 col-lg-6">
      <BaseText>
        Default paragraph text. FleetYards keeps a public roster of all known
        Star Citizen ships and their loadouts.
      </BaseText>
      <BaseText muted>
        Muted text, for secondary information that should recede.
      </BaseText>
    </div>
    <div class="col-12 col-lg-6">
      <BaseText no-spacing>First line, no bottom spacing.</BaseText>
      <BaseText no-spacing>Second line, sitting directly below it.</BaseText>
      <BaseText as="span">An inline span, </BaseText>
      <BaseText as="span" muted>followed by a muted one.</BaseText>
      <BaseText as="div">And a div.</BaseText>
    </div>
  </div>

  <Heading :level="HeadingLevelEnum.H2">Pill</Heading>
  <p>All variants, plus the uppercase and margin-right modifiers.</p>
  <div class="row">
    <div class="col-12">
      <BasePill
        v-for="variant in pillVariants"
        :key="`pill-${variant}`"
        :variant="variant"
        margin-right
      >
        {{ variant }}
      </BasePill>
    </div>
  </div>
  <div class="row">
    <div class="col-12">
      <BasePill
        v-for="variant in pillVariants"
        :key="`pill-uppercase-${variant}`"
        :variant="variant"
        uppercase
        margin-right
      >
        {{ variant }}
      </BasePill>
    </div>
  </div>
  <div class="row">
    <div class="col-12">
      <BasePill>No margin</BasePill>
      <BasePill>right, so these</BasePill>
      <BasePill>run together</BasePill>
    </div>
  </div>

  <Heading :level="HeadingLevelEnum.H2">Spacer</Heading>
  <p>
    Horizontal rules at each weight. Each one below is labelled with the props
    it carries.
  </p>
  <div class="row">
    <div class="col-12">
      <BaseText muted no-spacing>default</BaseText>
      <Spacer />
      <BaseText muted no-spacing>slim</BaseText>
      <Spacer slim />
      <BaseText muted no-spacing>large</BaseText>
      <Spacer large />
      <BaseText muted no-spacing>dark</BaseText>
      <Spacer dark />
      <BaseText muted no-spacing>mb</BaseText>
      <Spacer mb />
      <BaseText muted no-spacing>end</BaseText>
    </div>
  </div>

  <Heading :level="HeadingLevelEnum.H2">Box</Heading>
  <p>
    A slim panel with an optional heading and footer, in each panel variant.
  </p>
  <div class="row">
    <div class="col-12 col-lg-3">
      <Box>
        <template #heading>Default</template>
        Box content.
      </Box>
    </div>
    <div class="col-12 col-lg-3">
      <Box :variant="PanelVariantsEnum.PRIMARY">
        <template #heading>Primary</template>
        Box content.
      </Box>
    </div>
    <div class="col-12 col-lg-3">
      <Box :variant="PanelVariantsEnum.SUCCESS">
        <template #heading>Success</template>
        Box content.
      </Box>
    </div>
    <div class="col-12 col-lg-3">
      <Box :variant="PanelVariantsEnum.ERROR">
        <template #heading>Error</template>
        Box content.
      </Box>
    </div>
  </div>
  <div class="row">
    <div class="col-12 col-lg-6">
      <Box large>
        <template #heading>Large</template>
        Wider padding, used for empty states.
      </Box>
    </div>
    <div class="col-12 col-lg-6">
      <Box>
        <template #heading>With footer</template>
        The footer slot renders outside the panel.
        <template #footer>
          <BaseText muted no-spacing>Footer content</BaseText>
        </template>
      </Box>
    </div>
  </div>

  <Heading :level="HeadingLevelEnum.H2">Grid</Heading>
  <p>
    The responsive card grid. <code>grid-base</code> picks the column count at
    medium widths; <code>filter-visible</code> narrows the tracks to make room
    for a filter drawer. Resize to check the breakpoints.
  </p>
  <BaseGrid :records="gridRecords" primary-key="id">
    <template #default="{ record, index }">
      <Panel slim>
        <PanelBody>
          <BaseText no-spacing>{{ index + 1 }}. {{ record.name }}</BaseText>
          <BaseText muted no-spacing>{{ record.manufacturer }}</BaseText>
        </PanelBody>
      </Panel>
    </template>
  </BaseGrid>
  <BaseGrid :records="gridRecords" primary-key="id" grid-base="2">
    <template #default="{ record }">
      <Panel slim>
        <PanelBody>
          <BaseText no-spacing>{{ record.name }} — grid-base 2</BaseText>
        </PanelBody>
      </Panel>
    </template>
  </BaseGrid>
  <BaseGrid :records="gridRecords" primary-key="id" filter-visible>
    <template #default="{ record }">
      <Panel slim>
        <PanelBody>
          <BaseText no-spacing>{{ record.name }} — filter visible</BaseText>
        </PanelBody>
      </Panel>
    </template>
  </BaseGrid>
</template>
