import { messages as validationMessages } from "vee-validate/dist/locale/zh_CN.json";
import main from "./zh-CN/index";
import actions from "./zh-CN/actions";
import headlines from "./zh-CN/headlines";
import labels from "./zh-CN/labels";
import messages from "./zh-CN/messages";
import nav from "./zh-CN/nav";
import placeholders from "./zh-CN/placeholders";
import sublines from "./zh-CN/sublines";
import texts from "./zh-CN/texts";
import title from "./zh-CN/title";
import privacySettings from "./zh-CN/privacySettings";
import validationError from "./zh-CN/validationError";

const validations = {};
Object.keys(validationMessages).forEach((key) => {
  validations[key] = validationMessages[key].replace(/\{/g, "%{");
});

export default {
  ...main,
  title,
  privacySettings,
  headlines,
  sublines,
  nav,
  labels,
  placeholders,
  actions,
  texts,
  messages,
  validations,
  validation_error: validationError,
};
