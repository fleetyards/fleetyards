<script lang="ts">
export default {
  name: "FleetMemberName",
};
</script>

<script lang="ts" setup>
import BtnDropdown from "@/shared/components/base/BtnDropdown/index.vue";
import { BtnVariantsEnum } from "@/shared/components/base/Btn/types";
import { useI18n } from "@/shared/composables/useI18n";
import type { FleetMember } from "@/services/fyApi";

type Props = {
  member: FleetMember;
};

const props = defineProps<Props>();

const { t } = useI18n();

const hasContactOptions = computed(
  () => !!props.member.rsiHandle || !!props.member.discordProfileUrl,
);

const spectrumDmUrl = computed(() => {
  if (!props.member.rsiHandle) return null;
  return `https://robertsspaceindustries.com/spectrum/messages/member/${props.member.rsiHandle}`;
});
</script>

<template>
  <span class="member-name">
    <template v-if="hasContactOptions">
      <BtnDropdown :variant="BtnVariantsEnum.LINK" text-inline inline>
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
        <div class="member-name__dropdown-header">
          {{ t("labels.fleet.members.contact") }}
        </div>
        <a
          v-if="spectrumDmUrl"
          :href="spectrumDmUrl"
          target="_blank"
          rel="noopener"
          class="member-name__dropdown-item"
        >
          <i class="icon icon-rsi" />
          <span>{{ t("labels.fleet.members.spectrumDm") }}</span>
        </a>
        <a
          v-if="member.discordProfileUrl"
          :href="member.discordProfileUrl"
          target="_blank"
          rel="noopener"
          class="member-name__dropdown-item"
        >
          <i class="fa-brands fa-discord" />
          <span>{{ t("labels.fleet.members.discordContact") }}</span>
        </a>
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

  &__dropdown-header {
    padding: 8px 12px;
    font-size: 0.85em;
    font-weight: 600;
    opacity: 0.6;
  }

  &__dropdown-item {
    display: flex;
    align-items: center;
    gap: 10px;
    padding: 8px 12px;
    color: inherit;
    text-decoration: none;
    transition: background-color 0.15s ease;

    &:hover {
      background-color: rgba(255, 255, 255, 0.05);
    }

    i {
      display: flex;
      justify-content: center;
      width: 20px;
      font-size: 1.1em;
    }
  }
}
</style>
