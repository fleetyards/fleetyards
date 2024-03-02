import { extractTranslations, type MessagesJSON } from "@/translations/utils";

const files = import.meta.glob<Record<string, MessagesJSON>>("./**/*.json", {
  eager: true,
});

export default extractTranslations("es", files);
