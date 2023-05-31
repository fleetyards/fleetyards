import { messages as validationMessages } from "vee-validate/dist/locale/zh_TW.json";

import actions from "./zh-TW/actions";
import headlines from "./zh-TW/headlines";
import main from "./zh-TW/index";
import labels from "./zh-TW/labels";
import messages from "./zh-TW/messages";
import nav from "./zh-TW/nav";
import placeholders from "./zh-TW/placeholders";
import privacySettings from "./zh-TW/privacySettings";
import sublines from "./zh-TW/sublines";
import texts from "./zh-TW/texts";
import title from "./zh-TW/title";
import validationError from "./zh-TW/validationError";

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
