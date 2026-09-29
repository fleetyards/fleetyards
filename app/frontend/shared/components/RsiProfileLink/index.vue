<script lang="ts">
export default {
  name: "RsiProfileLink",
};
</script>

<script lang="ts" setup>
import { useI18n } from "@/shared/composables/useI18n";

type Props = {
  handle: string;
  citizenidProfileUrl?: string | null;
  iconOnly?: boolean;
};

const props = withDefaults(defineProps<Props>(), {
  citizenidProfileUrl: null,
  iconOnly: false,
});

const { t } = useI18n();

const rsiProfileUrl = computed(
  () => `https://robertsspaceindustries.com/citizens/${props.handle}`,
);
</script>

<template>
  <span class="rsi-profile-link">
    <a
      v-tooltip="t('nav.rsiProfile')"
      :aria-label="t('nav.rsiProfile')"
      :href="rsiProfileUrl"
      target="_blank"
      rel="noopener"
    >
      <template v-if="iconOnly">
        <i class="icon icon-rsi" />
      </template>
      <template v-else>
        {{ handle }}
      </template>
    </a>
    <a
      v-if="citizenidProfileUrl"
      v-tooltip="t('labels.user.rsiHandleVerified')"
      :aria-label="t('labels.user.rsiHandleVerified')"
      :href="citizenidProfileUrl"
      target="_blank"
      rel="noopener"
      class="rsi-profile-link__badge"
    >
      <i class="fa-duotone fa-badge-check text-success" />
    </a>
  </span>
</template>

<style lang="scss" scoped>
.rsi-profile-link {
  position: relative;
  display: inline-flex;
  align-items: center;

  // Centred on the right edge, so it overlaps the icon or the handle at any
  // size. The duotone shape is made opaque in the colour its default 40%
  // layer shows over the page, so what it overlaps does not show through.
  &__badge {
    position: absolute;
    z-index: 1;
    top: 0;
    right: 0;
    transform: translate(50%, 0);
    font-size: 0.65em;
    line-height: 1;
    --fa-secondary-color: color-mix(
      in srgb,
      currentColor 40%,
      var(--color-background, #000)
    );
    --fa-secondary-opacity: 1;
  }
}
</style>
