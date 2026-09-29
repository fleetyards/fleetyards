<script lang="ts">
export default {
  name: "FleetMemberAvatar",
};
</script>

<script lang="ts" setup>
import Avatar from "@/shared/components/Avatar/index.vue";
import SquadronEmblem from "@/frontend/components/Fleets/Squadrons/SquadronEmblem/index.vue";
import type { FleetMember } from "@/services/fyApi";
import { useI18n } from "@/shared/composables/useI18n";

type Props = {
  member: Pick<FleetMember, "avatar" | "squadrons" | "verifiedOrgSid">;
  online?: boolean;
  showSquadrons?: boolean;
};

const props = withDefaults(defineProps<Props>(), {
  online: undefined,
  showSquadrons: false,
});

const { t } = useI18n();

const squadronNames = computed(() =>
  (props.member.squadrons ?? []).map((squadron) => squadron.name).join(", "),
);
</script>

<template>
  <span class="member-avatar">
    <Avatar :avatar="member.avatar?.smallUrl" size="small" :online="online" />
    <span
      v-if="member.verifiedOrgSid"
      v-tooltip="
        t('labels.fleet.members.verifiedOrgMember', {
          sid: member.verifiedOrgSid,
        })
      "
      :aria-label="
        t('labels.fleet.members.verifiedOrgMember', {
          sid: member.verifiedOrgSid,
        })
      "
      class="member-avatar__verified"
      data-test="member-verified-org"
    >
      <i class="fa-duotone fa-shield-check text-success" />
    </span>
    <SquadronEmblem
      v-if="showSquadrons && member.squadrons?.length"
      v-tooltip="squadronNames"
      :squadron="member.squadrons[0]"
      :size="18"
      class="member-avatar__squadron"
    />
  </span>
</template>

<style lang="scss" scoped>
.member-avatar {
  position: relative;
  display: inline-flex;
  flex-shrink: 0;
}

// The top-right corner, the one neither the squadron nor the presence dot
// takes, inset the way the presence dot is below it. Opaque in the colour the
// default 40% duotone layer shows over the page, so the avatar does not show
// through it.
.member-avatar__verified {
  position: absolute;
  top: 0;
  right: 0;
  font-size: 14px;
  line-height: 1;
  --fa-secondary-color: color-mix(
    in srgb,
    currentColor 40%,
    var(--color-background, #000)
  );
  --fa-secondary-opacity: 1;
}

// Overhangs the frame the way the presence dot does, on the corner it leaves
// free.
.member-avatar__squadron {
  position: absolute;
  left: -4px;
  bottom: -4px;
}
</style>
