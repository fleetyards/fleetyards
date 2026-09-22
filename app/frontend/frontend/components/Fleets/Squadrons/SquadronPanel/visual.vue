<script lang="ts">
export default {
  name: "VisualTestsSquadronsPage",
};
</script>

<script lang="ts" setup>
import Heading from "@/shared/components/base/Heading/index.vue";
import { HeadingLevelEnum } from "@/shared/components/base/Heading/types";
import Panel from "@/shared/components/base/Panel/index.vue";
import PanelHeading from "@/shared/components/base/Panel/Heading/index.vue";
import PanelBody from "@/shared/components/base/Panel/Body/index.vue";
import Btn from "@/shared/components/base/Btn/index.vue";
import { BtnVariantsEnum } from "@/shared/components/base/Btn/types";
import {
  PanelVariantsEnum,
  PanelTonesEnum,
} from "@/shared/components/base/Panel/types";
import Grid from "@/shared/components/base/Grid/index.vue";
import SquadronEmblem from "@/frontend/components/Fleets/Squadrons/SquadronEmblem/index.vue";
import type { FleetSquadron } from "@/services/fyApi";

/*
 * Four treatments of the same card, at the width the squadron grid actually
 * uses. What differs is only how loudly a squadron's own colour speaks -- the
 * content is settled by the exec plan: emblem, name, description, member count.
 *
 * The fixtures are chosen for the cases that break a card rather than the ones
 * that flatter it: a long name, a long description, and a squadron with neither
 * colour nor logo.
 */
const squadron = (attributes: Partial<FleetSquadron>): FleetSquadron =>
  ({
    id: attributes.name ?? "x",
    slug: "combat-wing",
    memberCount: 12,
    ...attributes,
  }) as FleetSquadron;

const squadrons: FleetSquadron[] = [
  squadron({
    name: "Combat Wing",
    description: "The pointy end",
    color: "#dc3545",
    memberCount: 12,
  }),
  squadron({
    name: "Mining Division",
    description:
      "Ore, refining and the long haul back — everything that pays for the rest of it",
    color: "#d4af37",
    memberCount: 4,
  }),
  squadron({
    name: "Search and Rescue Standing Detachment",
    description: "On call",
    color: "#428bca",
    memberCount: 31,
  }),
  squadron({ name: "Reserves", memberCount: 0 }),
];

const toneStyle = (record: FleetSquadron) =>
  record.color ? { "--tone": record.color } : undefined;
</script>

<template>
  <Heading :level="HeadingLevelEnum.H2">
    A — slim frame, the squadron's colour on the edge
  </Heading>
  <p class="vt-note">
    The frame carries the colour. Loudest of the four, and the one that reads
    fastest across a grid — but four saturated edges at once is a lot of colour
    for a page that is otherwise grey.
  </p>
  <Grid :records="squadrons" primary-key="id">
    <template #default="{ record }">
      <Panel
        :variant="PanelVariantsEnum.SLIM"
        :tone="record.color ? PanelTonesEnum.PRIMARY : PanelTonesEnum.NEUTRAL"
        :style="toneStyle(record)"
        fill-height
      >
        <PanelHeading compact divider :level="HeadingLevelEnum.H3">
          <template #default>{{ record.name }}</template>
          <template v-if="record.description" #subtitle>
            {{ record.description }}
          </template>
          <template #actions>
            <Btn :variant="BtnVariantsEnum.BARE">
              <i class="fa-duotone fa-pen" />
            </Btn>
          </template>
        </PanelHeading>
        <PanelBody rounded="bottom" class="vt-squadron-body">
          <SquadronEmblem :squadron="record" />
          <div class="vt-squadron-count">
            <span class="vt-squadron-count-number">
              {{ record.memberCount }}
            </span>
            <span class="vt-squadron-count-label">Members</span>
          </div>
        </PanelBody>
      </Panel>
    </template>
  </Grid>

  <Heading :level="HeadingLevelEnum.H2">
    B — slim frame, the colour only in the emblem
  </Heading>
  <p class="vt-note">
    Neutral frame; the emblem is the only colour. Quietest, and closest to how
    the rest of the site treats a colour somebody picked. A squadron with no
    colour and no logo still gets an emblem, outlined rather than filled.
  </p>
  <Grid :records="squadrons" primary-key="id">
    <template #default="{ record }">
      <Panel :variant="PanelVariantsEnum.SLIM" fill-height>
        <PanelHeading compact divider :level="HeadingLevelEnum.H3">
          <template #default>{{ record.name }}</template>
          <template v-if="record.description" #subtitle>
            {{ record.description }}
          </template>
          <template #actions>
            <Btn :variant="BtnVariantsEnum.BARE">
              <i class="fa-duotone fa-pen" />
            </Btn>
          </template>
        </PanelHeading>
        <PanelBody rounded="bottom" class="vt-squadron-body">
          <SquadronEmblem :squadron="record" />
          <div class="vt-squadron-count">
            <span class="vt-squadron-count-number">
              {{ record.memberCount }}
            </span>
            <span class="vt-squadron-count-label">Members</span>
          </div>
        </PanelBody>
      </Panel>
    </template>
  </Grid>

  <Heading :level="HeadingLevelEnum.H2">
    C — slim frame, a colour rail down the left
  </Heading>
  <p class="vt-note">
    The rail the row list uses, stood on its end. The colour is present at full
    height but never surrounds the content, so it stays a marker rather than a
    frame.
  </p>
  <Grid :records="squadrons" primary-key="id">
    <template #default="{ record }">
      <Panel
        :variant="PanelVariantsEnum.SLIM"
        fill-height
        class="vt-squadron-railed"
      >
        <span
          class="vt-squadron-rail"
          :style="{ backgroundColor: record.color || 'var(--color-muted)' }"
        />
        <PanelHeading compact divider :level="HeadingLevelEnum.H3">
          <template #default>{{ record.name }}</template>
          <template v-if="record.description" #subtitle>
            {{ record.description }}
          </template>
          <template #actions>
            <Btn :variant="BtnVariantsEnum.BARE">
              <i class="fa-duotone fa-pen" />
            </Btn>
          </template>
        </PanelHeading>
        <PanelBody rounded="bottom" class="vt-squadron-body">
          <SquadronEmblem :squadron="record" />
          <div class="vt-squadron-count">
            <span class="vt-squadron-count-number">
              {{ record.memberCount }}
            </span>
            <span class="vt-squadron-count-label">Members</span>
          </div>
        </PanelBody>
      </Panel>
    </template>
  </Grid>

  <Heading :level="HeadingLevelEnum.H2">
    D — full frame, the colour on the end-caps
  </Heading>
  <p class="vt-note">
    The panel's own signature, which is what the redesign built tone for. The
    heaviest frame of the four; the plan's own note says a grid of repeated
    cards is where that weight turns to noise.
  </p>
  <Grid :records="squadrons" primary-key="id">
    <template #default="{ record }">
      <Panel
        :tone="record.color ? PanelTonesEnum.PRIMARY : PanelTonesEnum.NEUTRAL"
        :style="toneStyle(record)"
        fill-height
      >
        <PanelHeading :level="HeadingLevelEnum.H3">
          <template #default>{{ record.name }}</template>
          <template v-if="record.description" #subtitle>
            {{ record.description }}
          </template>
          <template #actions>
            <Btn :variant="BtnVariantsEnum.BARE">
              <i class="fa-duotone fa-pen" />
            </Btn>
          </template>
        </PanelHeading>
        <PanelBody rounded="bottom" class="vt-squadron-body">
          <SquadronEmblem :squadron="record" />
          <div class="vt-squadron-count">
            <span class="vt-squadron-count-number">
              {{ record.memberCount }}
            </span>
            <span class="vt-squadron-count-label">Members</span>
          </div>
        </PanelBody>
      </Panel>
    </template>
  </Grid>

  <Heading :level="HeadingLevelEnum.H2">Emblem sizes and fallbacks</Heading>
  <div class="row">
    <div class="col-12 vt-row">
      <SquadronEmblem
        v-for="record in squadrons"
        :key="`sm-${record.id}`"
        :squadron="record"
        :size="28"
      />
      <SquadronEmblem
        v-for="record in squadrons"
        :key="`lg-${record.id}`"
        :squadron="record"
        :size="64"
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

.vt-squadron-body {
  display: flex;
  align-items: center;
  gap: 12px;
}

.vt-squadron-count {
  display: flex;
  align-items: baseline;
  gap: 6px;
}

.vt-squadron-count-number {
  font-size: 1.5em;
  line-height: 1;
}

.vt-squadron-count-label {
  color: var(--color-text-dim);
  font-size: 0.85em;
}

.vt-squadron-railed {
  position: relative;
  overflow: hidden;
}

.vt-squadron-rail {
  position: absolute;
  left: 0;
  top: 0;
  bottom: 0;
  width: 4px;
}
</style>
