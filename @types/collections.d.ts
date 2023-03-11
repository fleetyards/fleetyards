type TRecordTypes =
  | TModel
  | TCelestialObject
  | TImage
  | TStarsystem
  | TVehicle
  | TUser
  | TStation
  | TShop
  | TCommodity
  | TEquipment
  | TManufacturer
  | THangarGroup
  | TModelPaint
  | TModelModule
  | TModelUpgrade
  | TModelModulePackage
  | TShopCommodity
  | TTradeRoute;

type TPagination = {
  currentPage: number;
  totalPages: number;
};

type TCollectionParams<T> = {
  search?: string;
  filters?: T;
  page?: number;
  cacheId?: string;
};

type TCollectionResponse<T> =
  | TCollectionSuccessResponse<T>
  | TCollectionErrorResponse;

type TCollectionSuccessResponse<T> = {
  data: T[];
};

type TCollectionErrorResponse = {
  error: string;
};

type TRecordResponse<T> = TRecordSuccessResponse<T> | TRecordErrorResponse;

type TRecordSuccessResponse<T> = {
  data: T;
};

type TRecordErrorResponse = {
  data?: undefined;
  error: string;
  errors?: TErrorMessages;
  message?: string;
};

type TPlainResponse = {
  code: string;
  message: string;
  field?: string;
};

type TApiError = {
  attribute: string;
  messages: TErrorMessage[];
};

type TErrorMessage = {
  message: string;
};

type TErrorMessages = Record<string, string[]>;
