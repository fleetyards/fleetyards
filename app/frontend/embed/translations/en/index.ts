import { extractTranslations, type MessagesJSON } from "@/translations/utils";
import datetime from "@/translations/en/datetime.json";
import number from "@/translations/en/number.json";
import model from "@/translations/en/models/model.json";

const files = import.meta.glob<Record<string, MessagesJSON>>("./**/*.json", {
  eager: true,
});

export default {
  ...extractTranslations("en", files),
  ...datetime.en,
  ...number.en,
  ...model.en,
};
