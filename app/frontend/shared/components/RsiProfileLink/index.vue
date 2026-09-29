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
  <span
    class="rsi-profile-link"
    :class="{ 'rsi-profile-link--icon': iconOnly }"
  >
    <a
      v-tooltip="t('nav.rsiProfile')"
      class="rsi-profile-link__link"
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

  // Around the logo exactly, so the badge is placed against the logo and not
  // against a line box that grows with the text the link sits in: in the
  // hangar's 30px link row that box stood well above the 24px logo.
  &--icon &__link {
    display: inline-flex;
  }

  // Past the right edge and above it, so only its corner touches the icon or
  // the handle, at any size. The duotone shape is made opaque in the colour
  // its default 40% layer shows over the page, so what it overlaps does not
  // show through.
  &__badge {
    position: absolute;
    z-index: 1;
    top: 0;
    right: 0;
    transform: translate(75%, -35%);

    font-size: 0.85em;
    line-height: 1;
    --fa-secondary-color: color-mix(
      in srgb,
      currentColor 40%,
      var(--color-background, #000)
    );
    --fa-secondary-opacity: 1;

    // The RSI logo is wide and ends in open space, so the badge moves in to
    // sit on the logo rather than beside it. Sized in px like the logo, which
    // is a fixed-size image: in em it grew with whatever text the link sat in,
    // three times its size in the hangar's 30px link row.
    .rsi-profile-link--icon & {
      transform: translate(25%, -35%);
      font-size: 12px;
    }
  }
}
</style>
