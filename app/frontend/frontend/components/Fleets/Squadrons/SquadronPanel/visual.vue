<script lang="ts">
export default {
  name: "VisualTestsSquadronsPage",
};
</script>

<script lang="ts" setup>
import Heading from "@/shared/components/base/Heading/index.vue";
import { HeadingLevelEnum } from "@/shared/components/base/Heading/types";
import Grid from "@/shared/components/base/Grid/index.vue";
import SquadronPanel from "@/frontend/components/Fleets/Squadrons/SquadronPanel/index.vue";
import SquadronEmblem from "@/frontend/components/Fleets/Squadrons/SquadronEmblem/index.vue";
import combatLogo from "@/images/org-icons/security.png";
import miningLogo from "@/images/org-icons/resources.png";
import type { FleetSquadron, MediaFile } from "@/services/fyApi";

/*
 * The fixtures are the cases that break a card rather than the ones that
 * flatter it: a name with no wrap point, a description long enough to run to
 * three lines, and a squadron carrying neither colour nor logo.
 */
const logo = (url: string): MediaFile => ({
  name: "squadron-logo.png",
  contentType: "image/png",
  size: 4_682,
  url,
  smallUrl: url,
  mediumUrl: url,
  largeUrl: url,
  xlargeUrl: url,
});

const squadron = (attributes: Partial<FleetSquadron>): FleetSquadron =>
  ({
    id: attributes.name ?? "x",
    slug: (attributes.name ?? "x").toLowerCase().replace(/\s+/g, "-"),
    memberCount: 12,
    ...attributes,
  }) as FleetSquadron;

// One per emblem state: a logo over a colour, a logo alone, a colour alone,
// and neither.
const squadrons: FleetSquadron[] = [
  squadron({
    name: "Combat Wing",
    shortDescription: "The pointy end",
    color: "#dc3545",
    logo: logo(combatLogo),
    memberCount: 12,
  }),
  squadron({
    name: "Mining Division",
    shortDescription: "Ore, refining\nand the long haul back",
    description:
      "Everything that pays for the rest of it.\n\nThe division runs the " +
      "survey ships, the refinery runs, and the hauls back to station.",
    logo: logo(miningLogo),
    memberCount: 4,
  }),
  squadron({
    name: "Search and Rescue Standing Detachment",
    shortDescription: "On call",
    color: "#428bca",
    memberCount: 31,
  }),
  squadron({ name: "Reserves", memberCount: 0 }),
];

const to = (record: FleetSquadron) => ({
  name: "visual-tests-squadrons",
  query: { squadron: record.slug },
});
</script>

<template>
  <Heading :level="HeadingLevelEnum.H2">The squadron card</Heading>
  <p class="vt-note">
    A slim panel, because a grid of repeated cards is what that variant is for.
    The squadron's colour is a rail down the left rather than the frame: at this
    size a full edge in a colour somebody picked surrounds the content and
    competes with it, while a rail stays a marker you can find across a grid.
  </p>
  <Grid :records="squadrons" primary-key="id">
    <template #default="{ record }">
      <SquadronPanel :squadron="record" :to="to(record)" />
    </template>
  </Grid>

  <Heading :level="HeadingLevelEnum.H2">With the management actions</Heading>
  <p class="vt-note">
    As fleet settings draws it. The actions are pinned to the corner by
    PanelHeading, so they clear the title however long it runs.
  </p>
  <Grid :records="squadrons" primary-key="id">
    <template #default="{ record }">
      <SquadronPanel
        :squadron="record"
        :to="to(record)"
        editable
        destroyable
        members-manageable
      />
    </template>
  </Grid>

  <Heading :level="HeadingLevelEnum.H2">Emblem sizes and fallbacks</Heading>
  <p class="vt-note">
    28px, the 56px the card uses, and 72px. Left to right in each row: a logo
    over a colour, a logo alone, a colour alone, and neither — the last outlined
    rather than filled, so an emblem nobody chose a colour for does not
    out-shout one somebody did.
  </p>
  <div class="row">
    <div class="col-12 vt-row">
      <SquadronEmblem
        v-for="record in squadrons"
        :key="`sm-${record.id}`"
        :squadron="record"
        :size="28"
      />
    </div>
    <div class="col-12 vt-row">
      <SquadronEmblem
        v-for="record in squadrons"
        :key="`md-${record.id}`"
        :squadron="record"
        :size="56"
      />
    </div>
    <div class="col-12 vt-row">
      <SquadronEmblem
        v-for="record in squadrons"
        :key="`lg-${record.id}`"
        :squadron="record"
        :size="72"
      />
    </div>
  </div>
</template>

<style lang="scss" scoped>
.vt-note {
  max-width: 70ch;
  margin-bottom: 16px;
  color: var(--color-text-dim);
}

.vt-row {
  display: flex;
  flex-wrap: wrap;
  align-items: center;
  gap: 12px;
  margin-bottom: 24px;
}
</style>
