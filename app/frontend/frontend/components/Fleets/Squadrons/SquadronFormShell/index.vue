<script lang="ts">
export default {
  name: "FleetSquadronFormShell",
};
</script>

<script lang="ts" setup>
import type { RouteRecordRaw } from "vue-router";
import FormActions from "@/shared/components/base/FormActions/index.vue";
import TabNavView from "@/shared/components/TabNavView/index.vue";
import TabNavViewItems from "@/shared/components/TabNavView/Items/index.vue";
import { useSquadronForm } from "@/frontend/composables/useSquadronForm";
import { type Fleet, type FleetSquadron } from "@/services/fyApi";

type Props = {
  fleet: Fleet;
  tabRoutes: RouteRecordRaw[];
  // Absent while a squadron is being created. Everything else about the form is
  // the same, which is why creating and editing one are the same page.
  squadron?: FleetSquadron;
  resourceAccess?: string[];
};

const props = withDefaults(defineProps<Props>(), {
  squadron: undefined,
  resourceAccess: undefined,
});

const fleet = computed(() => props.fleet);
const squadron = computed(() => props.squadron);

const {
  fields,
  fieldProps,
  validationSchema,
  meta,
  submitting,
  onSubmit,
  handleCancel,
} = useSquadronForm(fleet, squadron);
</script>

<template>
  <!--
    One form across both tabs. The tabs are a way of reading a form that would
    otherwise be seven fields long, not two forms: whichever one is open, the
    submit writes the lot. A squadron's pictures need no record to exist first
    -- the direct upload hands back a signed id of its own -- so a new squadron
    is written with its emblem already on it.
  -->
  <form id="fleet-squadron-form" @submit.prevent="onSubmit">
    <TabNavView>
      <template #nav>
        <TabNavViewItems
          :routes="props.tabRoutes"
          :authenticated="true"
          :resource-access="props.resourceAccess"
        />
      </template>
      <template #content>
        <router-view
          :fields="fields"
          :field-props="fieldProps"
          :validation-schema="validationSchema"
          :squadron="props.squadron"
        />

        <FormActions
          :submitting="submitting"
          form-id="fleet-squadron-form"
          :dirty="meta.dirty || meta.touched"
          @cancel="handleCancel"
        />
      </template>
    </TabNavView>
  </form>
</template>
