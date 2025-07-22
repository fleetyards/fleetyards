import { defineRule } from "vee-validate";
import { useRule as textRule } from "./rules/text";
import { useRule as userRule } from "./rules/user";
import { useRule as usernameTakenRule } from "./rules/usernameTaken";
import { useRule as hexColorRule } from "./rules/hexColor";
import { useRule as serialTakenRule } from "./rules/serialTaken";
import { useRule as fidTakenRule } from "./rules/fidTaken";
import { useRule as emailTakenRule } from "./rules/emailTaken";
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

  defineRule("emailTaken", emailTakenRule());
  defineRule("fidTaken", fidTakenRule());
  defineRule("serialTaken", serialTakenRule());
  defineRule("hexColor", hexColorRule());
  defineRule("user", userRule());
  defineRule("usernameTaken", usernameTakenRule());
  defineRule("text", textRule());
};
