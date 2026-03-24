<script lang="ts">
export default {
  name: "OauthApiPage",
};
</script>

<script lang="ts" setup>
import Panel from "@/shared/components/base/Panel/index.vue";
import PanelHeading from "@/shared/components/base/Panel/Heading/index.vue";
import PanelBody from "@/shared/components/base/Panel/Body/index.vue";
import BaseSpacer from "@/shared/components/base/Spacer/index.vue";
import Heading from "@/shared/components/base/Heading/index.vue";
import HeadingSmall from "@/shared/components/base/Heading/Small/index.vue";
import BasePill from "@/shared/components/base/Pill/index.vue";
import { HeadingSizeEnum } from "@/shared/components/base/Heading/types";
import { SwaggerUIBundle } from "swagger-ui-dist";

const schemaUrl = computed(() => `${window.OAUTH_ENDPOINT}/schema.yaml`);

const apiVersion = computed(() => window.API_VERSION);
const oasVersion = computed(() => window.API_OAS_VERSION);

const swagger = ref<SwaggerUIBundle>();

const validatorIconUrl = computed(
  () => `https://validator.swagger.io/validator?url=${schemaUrl.value}`,
);

const validatorUrl = computed(
  () => `https://validator.swagger.io/validator/debug?url=${schemaUrl.value}`,
);

function initSwaggerUI() {
  swagger.value = SwaggerUIBundle({
    dom_id: "#swagger-ui",
    url: schemaUrl.value,
    showCommonExtensions: true,
    filter: true,
    defaultModelRendering: "model",
    defaultModelExpandDepth: 3,
  });
}

onMounted(() => {
  initSwaggerUI();
});
</script>

<template>
  <Heading :size="HeadingSizeEnum.HERO" hero>
    FleetYards.net OAuth API
    <HeadingSmall>
      <BasePill>{{ apiVersion }}</BasePill>
      <BasePill variant="success">OAS {{ oasVersion }}</BasePill>
    </HeadingSmall>
  </Heading>

  <BaseSpacer />

  <Panel>
    <PanelHeading>Schema</PanelHeading>
    <PanelBody>
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
    </PanelBody>
  </Panel>
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
