/**
 * The shape a rejected orval mutation actually carries. The generated hooks
 * type their rejection as `unknown`, so every `.catch` needs to say what it is
 * reading before it can reach the server's message.
 */
export type ApiError = {
  response?: {
    data?: {
      code?: string;
      message?: string;
    };
  };
};
