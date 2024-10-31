<script lang="ts">
export default {
  name: "ApiPage",
};
</script>

<script lang="ts" setup>
import { SwaggerUIBundle } from "swagger-ui-dist";

const schemaUrl = computed(() => `${window.API_ENDPOINT}/schema.yaml`);

const apiVersion = computed(() => window.API_VERSION);
const oasVersion = computed(() => window.API_OAS_VERSION);

const swagger = ref<SwaggerUIBundle>();

const validatorIconUrl = computed(
  () => `https://validator.swagger.io/validator?url=${schemaUrl.value}`,
);

const validatorUrl = computed(
  () => `https://validator.swagger.io/validator/debug?url=${schemaUrl.value}`,
);

onMounted(() => {
  swagger.value = SwaggerUIBundle({
    dom_id: "#swagger-ui",
    url: schemaUrl.value,
    showCommonExtensions: true,
    filter: true,
    defaultModelRendering: "model",
    defaultModelExpandDepth: 3,
  });

  swagger.value?.initOAuth({
    clientId: "your-client-id",
    clientSecret: "",
    usePkceWithAuthorizationCodeGrant: true,
  });
});
</script>

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
        <p class="mt-4">
          “Strap into one of dozens of ships and embark on a life within the
          Star Citizen universe. Unbound by profession or skill sets, you choose
          the path of your own life.”
        </p>
        <p class="mt-4">
          This API provides basic Information about All Ships / Components /
          Manufacturers for the upcomming Space Simulation Star Citizen.
        </p>
        <h2 class="mt-8 text-2xl font-bold">Pagination</h2>
        <p class="mb-4">
          Requests that return multiple items will be paginated to
          <code class="hljs p-1 rounded">30</code> items by default. You can
          specify further pages with the
          <code class="hljs p-1 rounded">?page</code> parameter. For some
          resources, you can also set a custom page size up to
          <code class="hljs p-1 rounded">200</code> with the
          <code class="hljs p-1 rounded">?perPage</code> parameter. Note that
          for technical reasons not all endpoints respect the
          <code class="hljs p-1 rounded">?perPage</code> parameter, see events
          for example.
        </p>

        <p class="mb-4">
          <code class="hljs p-1 rounded"
            >curl 'https://api.fleetyards.net/models?page=2&perPage=200'</code
          >
        </p>
        <p class="mb-4">
          Note that page numbering is 1-based and that omitting the
          <code class="hljs p-1 rounded">?page</code> parameter will return the
          first page.
        </p>

        <h3 class="text-xl font-semibold">Link Header</h3>
        <p class="mb-4">The Link header includes pagination information:</p>

        <p class="mb-4">
          <code class="hljs p-1 rounded"
            >Link: &lt;https://api.fleetyards.net/models?page=1&perPage=200&gt;;
            rel="next",<br />
            &lt;https://api.fleetyards.net/models?page=2&perPage=200&gt;;
            rel="last"</code
          >
        </p>

        <p class="mb-4">The example includes a line break for readability.</p>

        <p class="mb-4">
          This Link response header contains one or more Hypermedia link
          relations, some of which may require expansion as URI templates.
        </p>

        <p class="mb-4">
          The possible <code class="hljs p-1 rounded">rel</code> values are:
        </p>

        <table class="table-auto w-full mb-4">
          <thead>
            <tr>
              <th class="px-4 py-2">Name</th>
              <th class="px-4 py-2">Description</th>
            </tr>
          </thead>
          <tbody>
            <tr>
              <td class="border px-4 py-2">next</td>
              <td class="border px-4 py-2">
                The link relation for the immediate next page of results.
              </td>
            </tr>
            <tr>
              <td class="border px-4 py-2">last</td>
              <td class="border px-4 py-2">
                The link relation for the last page of results.
              </td>
            </tr>
            <tr>
              <td class="border px-4 py-2">first</td>
              <td class="border px-4 py-2">
                The link relation for the first page of results.
              </td>
            </tr>
            <tr>
              <td class="border px-4 py-2">prev</td>
              <td class="border px-4 py-2">
                The link relation for the immediate previous page of results.
              </td>
            </tr>
          </tbody>
        </table>
        <h2 class="mt-8 text-2xl font-bold">Schema</h2>
        <a
          :href="schemaUrl"
          target="_blank"
          rel="noopener"
          class="text-brand-primary hover:text-brand-primary/80 transition-colors"
        >
          {{ schemaUrl }}
        </a>
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
  .swagger-ui .model-box-control,
  .swagger-ui .models-control,
  .swagger-ui .opblock-summary-control {
    gap: 5px;

    .opblock-summary-description {
      flex-grow: 2;
      text-align: right;
      font-size: 110%;
    }
  }
}
</style>
