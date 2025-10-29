<script lang="ts">
export default {
  name: "AppContact",
};
</script>

<script setup lang="ts">
import { computed } from "vue";

const appName = computed(() => window.APP_NAME);
const maintainerName = computed(() => window.MAINTAINER_NAME);
const maintainerMail = computed(() => window.MAINTAINER_MAIL);
const maintainerAddressStreet = computed(
  () => window.MAINTAINER_ADDRESS_STREET,
);
const maintainerAddressPostalcode = computed(
  () => window.MAINTAINER_ADDRESS_POSTALCODE,
);
const maintainerAddressCity = computed(() => window.MAINTAINER_ADDRESS_CITY);
const maintainerAddressCountry = computed(
  () => window.MAINTAINER_ADDRESS_COUNTRY,
);
</script>

<template>
  <address>
    <dl class="app-contact__dl-horizontal">
      <dd class="app-contact__name">
        {{ appName }}
      </dd>
      <dt>
        <strong>Address:</strong>
      </dt>
      <dd>
        {{ maintainerName }}<br />
        {{ maintainerAddressStreet }}<br />
        {{ maintainerAddressPostalcode }} {{ maintainerAddressCity }}<br />
        {{ maintainerAddressCountry }}
      </dd>
      <dt>
        <strong>Email:</strong>
      </dt>
      <dd>
        {{ maintainerMail }}
      </dd>
    </dl>
  </address>
</template>

<style lang="scss" scoped>
.app-contact__dl-horizontal {
  margin: 0;
  padding: 0;

  dt {
    font-weight: bold;
    margin-top: 0.5em;
  }

  dd {
    margin: 0 0 0.5em 0;

    &.app-contact__name {
      font-size: 1.2em;
      font-weight: 600;
      margin-bottom: 0.5em;
    }
  }
}
</style>
