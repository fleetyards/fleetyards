import { useI18n } from "@/frontend/composables/useI18n";
import logo from "@/images/favicon.png";
import { useRoute } from "vue-router";

type MetaType = "website" | "article";

export const useMetaInfo = () => {
  const route = useRoute();

  const { t } = useI18n();

  const routeTitle = computed(() => {
    const routeMetaTitle: string | undefined = route.meta?.title as
      | string
      | undefined;

    if (!routeMetaTitle) {
      return undefined;
    }

    return t(`title.${routeMetaTitle}`);
  });

  const titleElement = computed<HTMLTitleElement | null>(() =>
    document.querySelector("title")
  );

  const descriptionElement = computed<HTMLMetaElement | null>(() =>
    document.querySelector('meta[name="description"]')
  );

  const ogDescriptionElement = computed<HTMLMetaElement | null>(() =>
    document.querySelector('meta[property="og:description"]')
  );

  const ogTitleElement = computed<HTMLMetaElement | null>(() =>
    document.querySelector('meta[property="og:title"]')
  );

  const ogTypeElement = (): HTMLMetaElement | null =>
    document.querySelector('meta[property="og:type"]');

  const ogImageElement = (): HTMLMetaElement | null =>
    document.querySelector('meta[property="og:image"]');

  const ogUrlElement = (): HTMLMetaElement | null =>
    document.querySelector('meta[property="og:url"]');

  const getCurrentMetaInfo = () => {
    const currentTitle = titleElement.value?.text;
    const currentDescription = descriptionElement.value?.content;

    return {
      title: currentTitle,
      description: currentDescription,
      type: ogTypeElement()?.content,
      image: ogImageElement()?.content,
      url: ogUrlElement()?.content,
    };
  };

  const getTitle = (title?: string): string | undefined => {
    if (title) {
      return `${title} | ${t("app")}`;
    }

    if (routeTitle.value) {
      return `${routeTitle.value} | ${t("app")}`;
    }

    return undefined;
  };

  const getDescription = (description?: string): string => {
    if (description) {
      return description;
    }

    return t("meta.description");
  };

  const getType = (type?: MetaType): MetaType => {
    if (type) {
      return type;
    }

    return "website";
  };

  const getImage = (image?: string): string => {
    if (image) {
      return image;
    }

    const host = `${window.location.protocol}//${window.location.host}`;

    return `${host}${logo}`;
  };

  const updateMetaInfo = (
    title?: string,
    description?: string,
    image?: string,
    type?: MetaType
  ) => {
    const currentMetaTags = getCurrentMetaInfo();

    const newTitle = getTitle(title);
    if (newTitle && newTitle !== currentMetaTags.title) {
      document.title = newTitle;
      if (ogTitleElement.value) {
        ogTitleElement.value.content = newTitle;
      }
    }

    const newDescription = getDescription(description);
    if (
      newDescription !== currentMetaTags.description &&
      descriptionElement.value
    ) {
      descriptionElement.value.content = newDescription;
      if (ogDescriptionElement.value) {
        ogDescriptionElement.value.content = newDescription;
      }
    }

    const newType = getType(type);
    const typeElement = ogTypeElement();
    if (newType !== currentMetaTags.type && typeElement) {
      typeElement.content = newType;
    }

    const newImage = getImage(image);
    const imageElement = ogImageElement();
    if (newImage !== currentMetaTags.image && imageElement) {
      imageElement.content = newImage;
    }

    const urlElement = ogUrlElement();
    if (urlElement) {
      urlElement.content = window.location.href;
    }

    return getCurrentMetaInfo();
  };

  watch(
    () => route.meta?.title,
    () => {
      updateMetaInfo();
    }
  );

  onMounted(() => {
    updateMetaInfo();
  });

  return {
    updateMetaInfo,
  };
};
