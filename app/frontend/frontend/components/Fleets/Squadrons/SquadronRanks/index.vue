<script lang="ts">
export default {
  name: "SquadronRanks",
};
</script>

<script lang="ts" setup>
import Panel from "@/shared/components/base/Panel/index.vue";
import PanelHeading from "@/shared/components/base/Panel/Heading/index.vue";
import PanelBody from "@/shared/components/base/Panel/Body/index.vue";
import Btn from "@/shared/components/base/Btn/index.vue";
import { BtnVariantsEnum } from "@/shared/components/base/Btn/types";
import { HeadingLevelEnum } from "@/shared/components/base/Heading/types";
import { useI18n } from "@/shared/composables/useI18n";
import { useComlink } from "@/shared/composables/useComlink";
import type { FleetSquadronRole } from "@/services/fyApi";

type Props = {
  fleetSlug: string;
  ranks: FleetSquadronRole[];
  editable?: boolean;
};

const props = withDefaults(defineProps<Props>(), {
  editable: false,
});

const RIGHTS = ["singleHolder", "managesMembers", "managesRanks"] as const;

const { t } = useI18n();
const comlink = useComlink();

const openRenameModal = (rank: FleetSquadronRole) => {
  comlink.emit("open-modal", {
    component: () =>
      import("@/frontend/components/Fleets/Squadrons/SquadronRankModal/index.vue"),
    props: { fleetSlug: props.fleetSlug, rank },
  });
};
</script>

<template>
  <p class="squadron-ranks__hint">
    {{ t("labels.fleet.squadrons.ranksHint") }}
  </p>
  <div class="squadron-ranks">
    <Panel
      v-for="rank in ranks"
      :key="rank.id"
      :data-test="`squadron-rank-${rank.key}`"
    >
      <PanelHeading :level="HeadingLevelEnum.H3">
        {{ rank.name }}
        <span v-if="rank.permanent" class="squadron-rank-badge text-muted">
          ({{ t("labels.fleet.roles.permanent") }})
        </span>
        <span
          v-if="rank.defaultRank"
          class="squadron-rank-badge text-muted"
          :data-test="`squadron-rank-default-${rank.key}`"
        >
          ({{ t("labels.fleet.squadrons.defaultRank") }})
        </span>
        <template v-if="editable" #actions>
          <Btn
            v-tooltip="t('actions.edit')"
            :variant="BtnVariantsEnum.BARE"
            :aria-label="t('actions.edit')"
            :data-test="`squadron-rank-edit-${rank.key}`"
            @click="openRenameModal(rank)"
          >
            <i class="fa-duotone fa-pen" />
          </Btn>
        </template>
      </PanelHeading>
      <PanelBody>
        <ul class="squadron-rank-rights">
          <li
            v-for="right in RIGHTS"
            :key="right"
            class="squadron-rank-right"
            :class="{ active: rank[right] }"
          >
            <i
              :class="
                rank[right]
                  ? 'fa-solid fa-check text-success'
                  : 'fa-solid fa-times text-muted'
              "
            />
            {{ t(`labels.fleet.squadrons.rankRights.${right}`) }}
          </li>
        </ul>
      </PanelBody>
    </Panel>
  </div>
</template>

<style lang="scss" scoped>
.squadron-ranks__hint {
  color: var(--color-text-dim);
}

.squadron-rank-badge {
  font-size: 0.75em;
  font-weight: normal;
}

// The roles page's layout: one panel per rank, stacked.
.squadron-ranks {
  display: flex;
  flex-direction: column;
  gap: 20px;
}

.squadron-rank-rights {
  list-style: none;
  padding: 0;
  margin: 0;
}

.squadron-rank-right {
  display: flex;
  align-items: center;
  gap: 8px;
  padding: 4px 0;
  opacity: 0.5;

  &.active {
    opacity: 1;
  }

  i {
    width: 16px;
    text-align: center;
  }
}
</style>
