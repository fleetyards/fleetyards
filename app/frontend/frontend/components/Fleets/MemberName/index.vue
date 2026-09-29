<script lang="ts">
export default {
  name: "FleetMemberName",
};
</script>

<script lang="ts" setup>
import BtnDropdown from "@/shared/components/base/BtnDropdown/index.vue";
import MemberContactMenu from "@/frontend/components/base/MemberContactMenu/index.vue";
import { BtnVariantsEnum } from "@/shared/components/base/Btn/types";
import { useI18n } from "@/shared/composables/useI18n";
import type { MemberContact } from "@/frontend/components/base/MemberContactMenu/types";

type Props = {
  member: MemberContact;
  // Off where the caller shows the badge on the member's avatar instead.
  orgBadge?: boolean;
};

const props = withDefaults(defineProps<Props>(), {
  orgBadge: true,
});

const { t } = useI18n();

const hasContactOptions = computed(
  () => !!props.member.rsiHandle || !!props.member.discordProfileUrl,
);

const displayName = computed(
  () => props.member.nickname || props.member.username,
);

// The username never goes away, only moves to second place: it is what every
// link and lookup resolves on, and a nickname the fleet chose is not identity.
const secondaryName = computed(() =>
  props.member.nickname ? props.member.username : undefined,
);
</script>

<template>
  <span class="member-name">
    <template v-if="hasContactOptions">
      <BtnDropdown :variant="BtnVariantsEnum.BARE">
        <template #label>
          <span>{{ displayName }}</span>
          <span v-if="secondaryName" class="member-name__username">
            {{ secondaryName }}
          </span>
        </template>
        <MemberContactMenu :member="member" />
      </BtnDropdown>
    </template>
    <template v-else>
      <span>{{ displayName }}</span>
      <span v-if="secondaryName" class="member-name__username">
        {{ secondaryName }}
      </span>
    </template>
    <!-- The org this fleet proved it runs, not the member's own handle: that
         one is badged where the handle is shown. -->
    <span
      v-if="orgBadge && member.verifiedOrgSid"
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
      class="member-name__badge"
      data-test="member-verified-org"
    >
      <i class="fa-duotone fa-shield-check text-success" />
    </span>
  </span>
</template>

<style lang="scss" scoped>
.member-name {
  display: inline-flex;
  align-items: center;

  &__badge {
    font-size: 0.85em;
    line-height: 1;
  }

  &__username {
    margin-left: 0.35em;
    font-size: 0.85em;
    opacity: 0.8;
  }
}
</style>
