<template>
  <main class="api-page">
    <div class="px-4 sm:px-6 lg:px-8 py-6">
      <div class="p-6 bg-brand-grayBgDark/80 rounded">
        <h1 class="font-hero text-4xl mb-5 flex flex-wrap gap-1 items-start">
          <span>FleetYards.net API</span>
          <span
            class="bg-gray-500 font-sans text-white relative rounded-xl text-sm px-2 py-1"
            >{{ apiVersion }}</span
          >
          <span
            class="bg-lime-600 font-sans text-white relative rounded-xl text-sm px-2 py-1"
            >OAS {{ oasVersion }}</span
          >
        </h1>
        <a
          :href="schemaUrl"
          target="_blank"
          rel="noopener"
          class="text-brand-primary hover:text-brand-primary/80 transition transition-colors"
        >
          {{ schemaUrl }}
        </a>
        <p class="mt-4">
          “Strap into one of dozens of ships and embark on a life within the
          Star Citizen universe. Unbound by profession or skill sets, you choose
          the path of your own life.”
        </p>
        <p class="mt-4">
          This API provides basic Information about All Ships / Components /
          Manufacturers for the upcomming Space Simulation Star Citizen.
        </p>
        <div id="swagger-ui" class="swagger-ui-wrapper"></div>
        <div class="flex justify-end">
          <a target="_blank" rel="noopener noreferrer" :href="validatorUrl">
            <img :src="validatorIconUrl" alt="Online validator badge" />
          </a>
        </div>
      </div>
    </div>
  </main>
</template>

<script lang="ts" setup>
import SwaggerUI from "swagger-ui";

const schemaUrl = computed(() => `${window.API_ENDPOINT}/schema.yaml`);

const apiVersion = computed(() => window.API_VERSION);
const oasVersion = computed(() => window.API_OAS_VERSION);

const swagger = ref<SwaggerUI>();

const validatorIconUrl = computed(
  () => `https://validator.swagger.io/validator?url=${schemaUrl.value}`
);

const validatorUrl = computed(
  () => `https://validator.swagger.io/validator/debug?url=${schemaUrl.value}`
);

onMounted(() => {
  swagger.value = SwaggerUI({
    dom_id: "#swagger-ui",
    url: schemaUrl.value,
    showCommonExtensions: true,
    filter: true,
  });

  swagger.value.initOAuth({
    clientId: "your-client-id",
    clientSecret: "",
    usePkceWithAuthorizationCodeGrant: true,
  });
});
</script>

<script lang="ts">
export default {
  name: "ApiPage",
};
</script>

<style lang="scss">
.swagger-ui-wrapper {
  .title {
    padding-top: 1rem;
  }

  .swagger-ui {
    .information-container {
      display: none;
    }

    .wrapper {
      padding: 0;
      max-width: none;
    }

    .info .title {
      font-family: "Orbitron", sans-serif;
    }

    section h3 {
      font-family: "Orbitron", sans-serif;
    }
  }
}
</style>
