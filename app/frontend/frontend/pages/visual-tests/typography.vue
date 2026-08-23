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
import Markdown from "@/shared/components/Markdown/index.vue";
import Panel from "@/shared/components/base/Panel/index.vue";
import PanelBody from "@/shared/components/base/Panel/Body/index.vue";
import Spacer from "@/shared/components/base/Spacer/index.vue";
import {
  HeadingAlignmentEnum,
  HeadingLevelEnum,
  HeadingSizeEnum,
} from "@/shared/components/base/Heading/types";
import { PanelTonesEnum } from "@/shared/components/base/Panel/types";

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

/*
 * Markdown renders a deliberately small subset and escapes everything before it
 * adds a tag, and index.test.ts already proves the escaping and the link guard.
 * So what is left for a page is what the result looks like: whether escaped
 * markup reads as text, whether an unbroken string bursts its column, and
 * whether the headings sit right inside a panel.
 */
const markdownSample = [
  "# Report",
  "",
  "A paragraph with **bold**, `inline code` and a [link](https://fleetyards.net).",
  "Continued on the next line of the same paragraph.",
  "",
  "## Findings",
  "",
  "- First item",
  "- Second item with `code`",
  "- Third item",
  "",
  "### Deeper",
  "",
  "Headings shift two levels down, so a document heading never competes with the",
  "page's own.",
].join("\n");

// The escaping is unit-tested; this is here to show that the result is legible
// rather than a wall of entities.
const markdownHostile = [
  "# Passed through as text",
  "",
  // The escaped slash below is load-bearing: writing the closing tag out in
  // full would end this SFC's script block.
  "<script>alert(1)<\/script>",
  "",
  '<img src="x" onerror="alert(1)">',
  "",
  "A [javascript link](javascript:alert(1)) stays text, and so does a",
  "[data one](data:text/html,<h1>x</h1>).",
  "",
  '- An entity: &amp; and a quote: "quoted"',
  "- **Unbalanced bold and `unclosed code",
].join("\n");

const markdownOverflow = [
  "## Nothing to wrap on",
  "",
  "Reticulating-splines-Aegis-Dynamics-Idris-P-frigate-hangar-bay-capital-ship-identifier-0000000000",
  "",
  "`a-single-code-span-with-no-spaces-in-it-at-all-0000000000000000000000000000`",
].join("\n");

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
      <Box :tone="PanelTonesEnum.PRIMARY">
        <template #heading>Primary</template>
        Box content.
      </Box>
    </div>
    <div class="col-12 col-lg-3">
      <Box :tone="PanelTonesEnum.SUCCESS">
        <template #heading>Success</template>
        Box content.
      </Box>
    </div>
    <div class="col-12 col-lg-3">
      <Box :tone="PanelTonesEnum.ERROR">
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
      <Panel>
        <PanelBody>
          <BaseText no-spacing>{{ index + 1 }}. {{ record.name }}</BaseText>
          <BaseText muted no-spacing>{{ record.manufacturer }}</BaseText>
        </PanelBody>
      </Panel>
    </template>
  </BaseGrid>
  <BaseGrid :records="gridRecords" primary-key="id" grid-base="2">
    <template #default="{ record }">
      <Panel>
        <PanelBody>
          <BaseText no-spacing>{{ record.name }} — grid-base 2</BaseText>
        </PanelBody>
      </Panel>
    </template>
  </BaseGrid>
  <BaseGrid :records="gridRecords" primary-key="id" filter-visible>
    <template #default="{ record }">
      <Panel>
        <PanelBody>
          <BaseText no-spacing>{{ record.name }} — filter visible</BaseText>
        </PanelBody>
      </Panel>
    </template>
  </BaseGrid>

  <Heading :level="HeadingLevelEnum.H2">Markdown</Heading>
  <p>
    The small subset our generated report bodies use. Headings shift two levels
    down, so a document's own <code>#</code> cannot compete with the page.
  </p>
  <div class="row">
    <div class="col-12 col-lg-6">
      <Panel>
        <PanelBody>
          <Markdown :source="markdownSample" />
        </PanelBody>
      </Panel>
    </div>
    <div class="col-12 col-lg-6">
      <Panel>
        <PanelBody>
          <Markdown :source="markdownHostile" />
        </PanelBody>
      </Panel>
    </div>
  </div>
  <p class="text-muted">
    Right: everything outside the subset is escaped and shown as text, and a
    link that is not http or same-origin never becomes an href. Proven in
    <code>Markdown/index.test.ts</code>; here to check the result stays
    readable.
  </p>

  <Heading :level="HeadingLevelEnum.H2">Markdown | Nothing to wrap on</Heading>
  <p>
    A long unbroken string has no break opportunity, so this is where a
    paragraph bursts its column if the styles let it.
  </p>
  <div class="row">
    <!--
      col-6 and col-3 rather than col-lg-*: this project's `lg` starts at 1500px,
      so a col-lg-3 is full width on an ordinary laptop and would show nothing.
    -->
    <div class="col-6">
      <Panel>
        <PanelBody>
          <Markdown :source="markdownOverflow" />
        </PanelBody>
      </Panel>
    </div>
    <div class="col-3">
      <Panel>
        <PanelBody>
          <Markdown :source="markdownOverflow" />
        </PanelBody>
      </Panel>
    </div>
  </div>

  <Heading :level="HeadingLevelEnum.H2">Markdown | Empty</Heading>
  <p>An empty source renders nothing at all, not an empty box.</p>
  <div class="row">
    <div class="col-12 col-lg-4">
      <Panel>
        <PanelBody>
          <Markdown />
        </PanelBody>
      </Panel>
    </div>
  </div>
</template>
