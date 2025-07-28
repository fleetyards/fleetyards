<script lang="ts">
export default {
  name: "VehicleNamingModalAlternativeNamesInput",
};
</script>

<script lang="ts" setup>
import { useField } from "vee-validate";
import { useI18n } from "@/shared/composables/useI18n";
import FormInput from "@/shared/components/base/FormInput/index.vue";
import Btn from "@/shared/components/base/Btn/index.vue";

type Props = {
  currentName?: string | null;
  name?: string;
};

const props = withDefaults(defineProps<Props>(), {
  currentName: undefined,
  name: "alternativeNames",
});

const modelValue = defineModel<string[]>({ default: [] });

const { t } = useI18n();

const { value: inputValue } = useField(props.name, undefined, {
  initialValue: modelValue,
  label: t(`labels.vehicle.alternativeNames`),
});

const innerValue = ref(inputValue.value);

const addName = () => {
  innerValue.value.push("");
};

const removeName = (index: number) => {
  innerValue.value.splice(index, 1);
};

const emits = defineEmits<{
  (e: "update:modelValue", value: string[]): void;
  (e: "use-name", name: string): void;
}>();

const useName = (index: number) => {
  const newName = innerValue.value[index];
  if (props.currentName) {
    innerValue.value[index] = props.currentName;
  }
  emits("use-name", newName);
};

const onChange = () => {
  emits("update:modelValue", innerValue.value);
};
</script>

<template>
  <div class="row alternative-names">
    <div class="col-12">
      <hr />
      <h3>
        <span>
          {{ t("headlines.hangar.alternativeNames") }}
        </span>
        <Btn
          data-test="vehicle-add-name"
          :inline="true"
          variant="link"
          @click="addName"
        >
          <i class="fal fa-plus" />
        </Btn>
      </h3>
    </div>
    <div
      v-for="(_name, index) in innerValue"
      :key="`alternative-name-${index}`"
      class="col-12"
    >
      <div class="form-group">
        <div class="input-group-flex">
          <FormInput
            v-model="innerValue[index]"
            :name="`vehicle-alternativeNames-${index}`"
            translation-key="name"
            :no-label="true"
            @input="onChange"
          />
          <Btn
            v-tooltip="t('actions.hangar.useName')"
            data-test="vehicle-switch-name"
            :inline="true"
            variant="link"
            @click="useName(index)"
          >
            <i class="fad fa-repeat" />
          </Btn>
          <Btn
            v-tooltip="t('actions.remove')"
            data-test="vehicle-add-name"
            :inline="true"
            variant="link"
            @click="removeName(index)"
          >
            <i class="fal fa-times" />
          </Btn>
        </div>
      </div>
    </div>
  </div>
</template>
