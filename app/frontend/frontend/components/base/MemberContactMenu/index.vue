<script lang="ts">
export default {
  name: "MemberContactMenu",
};
</script>

<script lang="ts" setup>
import { useI18n } from "@/shared/composables/useI18n";
import type { MemberContact } from "@/frontend/components/base/MemberContactMenu/types";

type Props = {
  member: MemberContact;
  hangar?: boolean;
};

const props = withDefaults(defineProps<Props>(), {
  hangar: false,
});

const { t } = useI18n();

const spectrumDmUrl = computed(() => {
  if (!props.member.rsiHandle) return null;

  return `https://robertsspaceindustries.com/spectrum/messages/member/${props.member.rsiHandle}`;
});

const hangarUrl = computed(() => {
  if (!props.hangar || !props.member.username) return null;

  return `/hangar/${props.member.username}`;
});

const hasContactOptions = computed(
  () => !!spectrumDmUrl.value || !!props.member.discordProfileUrl,
);
</script>

<template>
  <a
    v-if="hangarUrl"
    :href="hangarUrl"
    target="_blank"
    rel="noopener"
    class="member-contact-menu-item"
  >
    <i class="fa-duotone fa-bookmark" />
    <span>{{ t("labels.hangar") }}</span>
  </a>
  <div v-if="hasContactOptions" class="member-contact-menu-header">
    {{ t("labels.fleet.members.contact") }}
  </div>
  <a
    v-if="spectrumDmUrl"
    :href="spectrumDmUrl"
    target="_blank"
    rel="noopener"
    class="member-contact-menu-item"
  >
    <i class="icon icon-rsi" />
    <span>{{ t("labels.fleet.members.spectrumDm") }}</span>
  </a>
  <a
    v-if="member.discordProfileUrl"
    :href="member.discordProfileUrl"
    target="_blank"
    rel="noopener"
    class="member-contact-menu-item"
  >
    <i class="fa-brands fa-discord" />
    <span>{{ t("labels.fleet.members.discordContact") }}</span>
  </a>
</template>

<style lang="scss" scoped>
.member-contact-menu-header {
  padding: 8px 12px;
  font-size: 0.85em;
  font-weight: 600;
  opacity: 0.6;
}

.member-contact-menu-item {
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
</style>
