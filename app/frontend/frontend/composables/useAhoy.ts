import ahoy from "ahoy.js";

ahoy.configure({
  cookies: false,
});

export const useAhoy = () => {
  ahoy.trackView();
  ahoy.trackSubmits("form");
};
