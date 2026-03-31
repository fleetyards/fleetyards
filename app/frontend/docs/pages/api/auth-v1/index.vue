<script lang="ts">
export default {
  name: "AuthApiSchemaPage",
};
</script>

<script lang="ts" setup>
import Panel from "@/shared/components/base/Panel/index.vue";
import PanelBody from "@/shared/components/base/Panel/Body/index.vue";
import FormInput from "@/shared/components/base/FormInput/index.vue";
import Heading from "@/shared/components/base/Heading/index.vue";
import BasePill from "@/shared/components/base/Pill/index.vue";
import { HeadingSizeEnum } from "@/shared/components/base/Heading/types";
import { BtnSizesEnum } from "@/shared/components/base/Btn/types";
import { SwaggerUIBundle } from "swagger-ui-dist";
import copyText from "@/shared/utils/CopyText";
import { useI18n } from "@/shared/composables/useI18n";
import { useAppNotifications } from "@/shared/composables/useAppNotifications";

const { t } = useI18n();
const { displayInfo, displayAlert } = useAppNotifications();

const schemaUrl = computed(() => `${window.OAUTH_ENDPOINT}/v1/schema.yaml`);

const copySchemaUrl = () => {
  copyText(schemaUrl.value).then(
    () => displayInfo({ text: t("messages.copy.success") }),
    () => displayAlert({ text: t("messages.copy.failure") }),
  );
};

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
    dom_id: "#swagger-ui-auth",
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
  <div class="heading-row">
    <Heading :size="HeadingSizeEnum.HERO" hero>
      FleetYards.net Auth API
    </Heading>
    <div class="version-pills">
      <BasePill>{{ apiVersion }}</BasePill>
      <BasePill variant="success">OAS {{ oasVersion }}</BasePill>
    </div>
  </div>

  <Panel>
    <PanelBody>
      <div class="schema-url-row">
        <FormInput
          name="schemaUrl"
          :model-value="schemaUrl"
          :disabled="true"
          no-label
          inline
        />
        <Btn :size="BtnSizesEnum.SMALL" inline @click="copySchemaUrl">
          <i class="fa-duotone fa-copy" />
        </Btn>
      </div>
      <div id="swagger-ui-auth" class="swagger-ui-wrapper"></div>
      <div class="validator-badge">
        <a target="_blank" rel="noopener noreferrer" :href="validatorUrl">
          <img :src="validatorIconUrl" alt="Online validator badge" />
        </a>
      </div>
    </PanelBody>
  </Panel>
</template>

<style lang="scss" scoped>
.heading-row {
  display: flex;
  align-items: center;
  justify-content: space-between;
}

.version-pills {
  display: flex;
  gap: 0.5rem;
}

.schema-url-row {
  display: flex;
  align-items: center;
  gap: 0.5rem;
  max-width: 600px;
  margin: 0 auto 1rem;

  :deep(.base-input) {
    flex: 1;
  }
}

.validator-badge {
  display: flex;
  justify-content: flex-end;
}
</style>

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
