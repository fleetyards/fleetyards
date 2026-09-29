<script lang="ts">
export default {
  name: "FleetFid",
};
</script>

<script lang="ts" setup>
import { useI18n } from "@/shared/composables/useI18n";

type Props = {
  fid: string;
  // Only when the FID is the SID the fleet proved: a claimant still on its
  // temporary `X-N` is verified for `X`, not for `X-N`.
  verified?: boolean;
};

withDefaults(defineProps<Props>(), {
  verified: false,
});

const { t } = useI18n();
</script>

<template>
  <span class="fleet-fid"
    >{{ fid
    }}<i
      v-if="verified"
      v-tooltip="t('labels.fleet.rsiVerification.verified')"
      :aria-label="t('labels.fleet.rsiVerification.verified')"
      class="fa-duotone fa-badge-check text-success fleet-fid__badge"
      data-test="fleet-rsi-verified"
  /></span>
</template>

<style lang="scss" scoped>
.fleet-fid {
  position: relative;
}

// Centred on the FID's right edge, so it overlaps the last letter and reads
// as marking that FID whatever its size. The duotone shape is made opaque in
// the colour its default 40% layer shows over the page, so the letter it
// overlaps does not show through.
.fleet-fid__badge {
  position: absolute;
  z-index: 1;
  top: 0;
  right: 0;
  transform: translate(50%, 0);
  font-size: 0.6em;
  line-height: 1;
  --fa-secondary-color: color-mix(
    in srgb,
    currentColor 40%,
    var(--color-background, #000)
  );
  --fa-secondary-opacity: 1;
}
</style>
