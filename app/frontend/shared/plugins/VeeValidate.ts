import type { App } from "vue";
import type { I18nPluginOptions } from "@/shared/plugins/I18n";
import {
  ValidationProvider,
  ValidationObserver,
  extend,
  configure,
} from "vee-validate";
/* eslint-disable camelcase */
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
} from "vee-validate/dist/rules";
/* eslint-enable camelcase */
import {
  emailTaken,
  serialTaken,
  fidTaken,
  user,
  usernameTaken,
  url,
  hexColor,
  text,
} from "@/shared/plugins/VeeValidate/rules";

export default {
  install: (app: App<Element>, i18nComposable: () => I18nPluginOptions) => {
    const { t } = i18nComposable();

    configure({
      defaultMessage(_, values) {
        return t(`validations.${values._rule_}`, values);
      },
    });

    app.component("ValidationObserver", ValidationObserver);
    app.component("ValidationProvider", ValidationProvider);

    extend("required", required);
    extend("url", url);
    extend("alpha_dash", alpha_dash);
    extend("confirmed", confirmed);
    extend("regex", regex);
    extend("min", min);
    extend("min_value", min_value);
    extend("numeric", numeric);
    extend("between", between);
    extend("email", email);
    extend("emailTaken", emailTaken);
    extend("serialTaken", serialTaken);
    extend("usernameTaken", usernameTaken);
    extend("user", user);
    extend("fidTaken", fidTaken);
    extend("hexColor", hexColor);
    extend("text", text);
  },
};
