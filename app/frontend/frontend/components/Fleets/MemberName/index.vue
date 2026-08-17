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
};

const props = defineProps<Props>();

const { t } = useI18n();

const hasContactOptions = computed(
  () => !!props.member.rsiHandle || !!props.member.discordProfileUrl,
);
</script>

<template>
  <span class="member-name">
    <template v-if="hasContactOptions">
      <BtnDropdown :variant="BtnVariantsEnum.BARE">
        <template #label>
          <span>{{ member.username }}</span>
          <span
            v-if="member.citizenidProfileUrl"
            v-tooltip="t('labels.user.rsiHandleVerified')"
            class="member-name__badge"
          >
            <i class="fa-duotone fa-badge-check text-success" />
          </span>
        </template>
        <MemberContactMenu :member="member" />
      </BtnDropdown>
    </template>
    <template v-else>
      <span>{{ member.username }}</span>
    </template>
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
}
</style>
