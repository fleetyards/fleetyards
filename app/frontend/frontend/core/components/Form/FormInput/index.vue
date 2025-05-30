<template>
  <div :key="innerId" class="form-input" :class="cssClasses">
    <transition name="fade">
      <label
        v-show="!hideLabelOnEmpty || inputValue"
        v-if="innerLabel && !noLabel"
        :for="id"
      >
        <i v-if="icon" :class="icon" />
        {{ innerLabel }}
      </label>
    </transition>
    <div
      class="form-input-wrapper"
      :class="{
        'from-input-wrapper-with-prefix': !!prefix,
        'from-input-wrapper-with-suffix': !!suffix,
      }"
    >
      <slot name="prefix">
        <div v-if="prefix" class="form-input-prefix">
          {{ prefix }}
        </div>
      </slot>
      <input
        :id="innerId"
        ref="input"
        v-model="inputValue"
        v-tooltip.right="error"
        :placeholder="innerPlaceholder"
        :type="type"
        :data-test="`input-${id}`"
        :aria-label="innerLabel"
        :autofocus="autofocus"
        :autocomplete="autocomplete"
        :disabled="disabled"
        :name="id"
        :min="min"
        :max="max"
        :step="innerStep"
        :class="{
          clearable,
        }"
        @input="update"
        @blur="update"
      />
      <slot name="suffix">
        <div v-if="suffix" class="form-input-suffix">
          {{ suffix }}
        </div>
      </slot>
      <div v-if="inputValue && clearable" class="clear">
        <i
          class="fal fa-times"
          :class="{
            'with-label': !!innerLabel && !noLabel,
          }"
          @click="clear"
        />
      </div>
    </div>
  </div>
</template>

<script lang="ts">
import Vue from "vue";
import { Component, Prop, Watch } from "vue-property-decorator";

@Component<FormInput>({})
export default class FormInput extends Vue {
  @Prop({ required: true }) id!: string;

  @Prop({ default: null }) icon!: string;

  @Prop({ default: null }) value!: string | number;

  @Prop({
    default: "text",
    validator(value) {
      return ["text", "number", "password", "email", "url", "color"].includes(
        value,
      );
    },
  })
  type!: string;

  @Prop({ default: null }) error!: string;

  @Prop({ default: null }) translationKey!: string;

  @Prop({ default: false }) autofocus!: boolean;

  @Prop({ default: undefined }) autocomplete!: string;

  @Prop({ default: false }) hideLabelOnEmpty!: boolean;

  @Prop({ default: null }) label!: string;

  @Prop({ default: null }) min!: number;

  @Prop({ default: null }) max!: number;

  @Prop({ default: 0.01 }) step!: number;

  @Prop({ default: false }) noLabel!: boolean;

  @Prop({ default: false }) noPlaceholder!: boolean;

  @Prop({ default: null }) placeholder!: string;

  @Prop({ default: false }) clearable!: boolean;

  @Prop({ default: false }) disabled!: boolean;

  @Prop({ default: false }) inline!: boolean;

  @Prop({ default: null }) prefix!: string;

  @Prop({ default: null }) suffix!: string;

  @Prop({
    default: "default",
    validator(value) {
      return ["default", "clean"].indexOf(value) !== -1;
    },
  })
  variant!: string;

  @Prop({
    default: "default",
    validator(value) {
      return ["default", "large"].indexOf(value) !== -1;
    },
  })
  size!: string;

  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  inputValue: any = null;

  get innerId() {
    return `${this.id}-${this._uid}`;
  }

  get innerStep() {
    if (this.type === "number") {
      return this.step;
    }

    return undefined;
  }

  get innerLabel() {
    if (this.label) {
      return this.label;
    }

    if (this.translationKey) {
      return this.$t(`labels.${this.translationKey}`);
    }

    return this.$t(`labels.${this.id}`);
  }

  get innerPlaceholder() {
    if (this.noPlaceholder) {
      return null;
    }

    if (this.placeholder) {
      return this.placeholder;
    }

    if (this.translationKey) {
      return this.$t(`placeholders.${this.translationKey}`);
    }

    return this.$t(`placeholders.${this.id}`);
  }

  get cssClasses() {
    return {
      "has-error has-feedback": this.error,
      "form-input-large": this.size === "large",
      "form-input-clean": this.variant === "clean",
      "form-input-clearable": this.clearable,
      "form-input-disabled": this.disabled,
      "form-input-inline": this.inline,
      [`form-input-${this.type}`]: true,
    };
  }

  @Watch("value")
  onValueChange() {
    this.inputValue = this.value;
  }

  mounted() {
    this.inputValue = this.value;

    if (this.autofocus) {
      this.setFocus();
    }
  }

  setFocus() {
    if (this.$refs.input) {
      this.$refs.input.focus();
    }
  }

  update() {
    this.$emit("input", this.inputValue);
  }

  clear() {
    this.inputValue = null;
    this.update();
    this.$emit("clear");
  }
}
</script>
