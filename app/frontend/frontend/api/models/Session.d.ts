type TSession = {
  token: string;
  expires: string;
};

type TSessionParams = {
  login: string;
  password: string;
  rememberMe: boolean;
};
