import { defineRule } from "vee-validate";
import {
  required,
  email,
  alpha_dash,
  numeric,
  between,
  min,
  min_value,
  confirmed,
  regex,
  url,
} from "@vee-validate/rules";

export const setupRules = () => {
  defineRule("required", required);
  defineRule("alpha_dash", alpha_dash);
  defineRule("confirmed", confirmed);
  defineRule("regex", regex);
  defineRule("min", min);
  defineRule("min_value", min_value);
  defineRule("numeric", numeric);
  defineRule("between", between);
  defineRule("email", email);
  defineRule("url", url);
};
