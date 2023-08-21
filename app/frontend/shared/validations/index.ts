import { defineRule } from "vee-validate";
import { useRule as textRule } from "./rules/text";
import { useRule as userRule } from "./rules/user";
import { useRule as usernameTakenRule } from "./rules/usernameTaken";
import { useRule as hexColorRule } from "./rules/hexColor";
import { useRule as serialTakenRule } from "./rules/serialTaken";
import { useRule as fidTakenRule } from "./rules/fidTaken";
import { useRule as emailTakenRule } from "./rules/emailTaken";
import type { I18nPluginOptions } from "@/shared/plugins/I18n";
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

export const setupRules = (
  t: I18nPluginOptions["t"],
  currentLocale: I18nPluginOptions["currentLocale"]
) => {
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

  defineRule("emailTaken", emailTakenRule(t, currentLocale));
  defineRule("fidTaken", fidTakenRule(t, currentLocale));
  defineRule("serialTaken", serialTakenRule(t, currentLocale));
  defineRule("hexColor", hexColorRule(t));
  defineRule("user", userRule(t, currentLocale));
  defineRule("usernameTaken", usernameTakenRule(t, currentLocale));
  defineRule("text", textRule(t));
};
