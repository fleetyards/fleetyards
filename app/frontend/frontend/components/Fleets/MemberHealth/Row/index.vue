<script lang="ts">
export default {
  name: "FleetMemberHealthRow",
};
</script>

<script lang="ts" setup>
import type { RouteLocationRaw } from "vue-router";
import Avatar from "@/shared/components/Avatar/index.vue";

type Props = {
  title: string;
  to?: RouteLocationRaw;
  avatar?: string;
  // Text in the avatar's place, for a row that is not a person.
  mark?: string;
  subline?: string;
  chip?: string;
  // A leader's role is marked: their absence leaves a gap a member's does not.
  chipLoud?: boolean;
  fact?: string;
  factSub?: string;
  factLoud?: boolean;
};

withDefaults(defineProps<Props>(), {
  to: undefined,
  avatar: undefined,
  mark: undefined,
  subline: undefined,
  chip: undefined,
  chipLoud: false,
  fact: undefined,
  factSub: undefined,
  factLoud: false,
});
</script>

<template>
  <li class="health-row">
    <span v-if="mark" class="health-row__mark" aria-hidden="true">
      {{ mark }}
    </span>
    <Avatar v-else :avatar="avatar" size="small" />
    <span class="health-row__name">
      <router-link v-if="to" :to="to" class="health-row__title">
        {{ title }}
      </router-link>
      <span v-else class="health-row__title">{{ title }}</span>
      <span v-if="subline" class="health-row__subline">{{ subline }}</span>
    </span>
    <span
      v-if="chip"
      class="health-row__chip"
      :class="{ 'health-row__chip--loud': chipLoud }"
    >
      {{ chip }}
    </span>
    <span v-if="fact" class="health-row__fact">
      <span :class="{ 'health-row__fact--loud': factLoud }">{{ fact }}</span>
      <span v-if="factSub" class="health-row__fact-sub">{{ factSub }}</span>
    </span>
    <span v-if="$slots.actions" class="health-row__actions">
      <slot name="actions" />
    </span>
  </li>
</template>

<style lang="scss" scoped>
.health-row {
  display: flex;
  flex-wrap: wrap;
  align-items: center;
  gap: 8px 14px;
  padding: 10px 20px;
  border-bottom: 1px solid rgb(122 130 136 / 0.15);

  &:last-child {
    border-bottom: 0;
  }
}

.health-row__mark {
  display: flex;
  flex: 0 0 auto;
  align-items: center;
  justify-content: center;
  width: 32px;
  height: 32px;
  border-radius: 3px;
  background: rgb(66 139 202 / 0.15);
  color: var(--color-primary-tint, #92bce0);
  font-size: 12px;
  font-weight: 700;
}

.health-row__name {
  display: flex;
  flex: 1 1 180px;
  flex-direction: column;
  min-width: 0;
}

.health-row__title {
  overflow: hidden;
  color: var(--color-lifted, #eee);
  font-weight: 600;
  text-overflow: ellipsis;
  white-space: nowrap;
}

.health-row__subline,
.health-row__fact-sub {
  color: var(--color-text-dim, #959595);
  font-size: 12px;
}

.health-row__chip {
  flex: 0 0 auto;
  padding: 2px 8px;
  border: 1px solid rgb(122 130 136 / 0.4);
  border-radius: 3px;
  font-size: 12px;
}

.health-row__chip--loud {
  border-color: var(--color-warning, #fa6800);
  color: var(--color-warning, #fa6800);
  font-weight: 700;
}

.health-row__fact {
  display: flex;
  flex: 0 1 240px;
  flex-direction: column;
  font-size: 13px;
  text-align: right;
}

.health-row__fact--loud {
  color: var(--color-warning, #fa6800);
}

.health-row__actions {
  display: flex;
  flex: 0 0 auto;
  gap: 6px;
}
</style>
