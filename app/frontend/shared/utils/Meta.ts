export const csrfToken = () =>
  (document.querySelector("meta[name=csrf-token]") as HTMLMetaElement).content;
