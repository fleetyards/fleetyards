type TUser = {
  id: string;
  username: string;
  twoFactorRequired: boolean;
  rsiHandle?: string;
  homepage?: string;
  discord?: string;
  youtube?: string;
  twitch?: string;
  guilded?: string;
  avatar?: string;
  publicHangar: boolean;
  publicHangarLoaners: boolean;
  publicWishlist: boolean;
  hideOwner: boolean;
  publicHangarUrl: string;
};

type TUserForm = {
  rsiHandle?: string;
  homepage?: string;
  discord?: string;
  youtube?: string;
  twitch?: string;
  guilded?: string;
  removeAvatar?: boolean;
  publicHangar: boolean;
  publicHangarLoaners: boolean;
};

type TSignupForm = {
  username: string;
  email: string;
  password: string;
  passwordConfirmation: string;
  saleNotify?: boolean;
  fleetInviteToken?: string;
};

type TUserAccountForm = {
  username: string;
  email: string;
};
