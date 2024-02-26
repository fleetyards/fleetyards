/* generated using openapi-typescript-codegen -- do no edit */
/* istanbul ignore file */
/* tslint:disable */
/* eslint-disable */
import type { CommodityPrice } from '../models/CommodityPrice';
import type { CommodityPriceInput } from '../models/CommodityPriceInput';
import type { CancelablePromise } from '../core/CancelablePromise';
import type { BaseHttpRequest } from '../core/BaseHttpRequest';
export class CommodityPricesService {
    constructor(public readonly httpRequest: BaseHttpRequest) {}
    /**
     * Create Commodity Price
     * @returns CommodityPrice successful
     * @throws ApiError
     */
    public createPrice({
        requestBody,
    }: {
        requestBody: CommodityPriceInput,
    }): CancelablePromise<CommodityPrice> {
        return this.httpRequest.request({
            method: 'POST',
            url: '/commodity-prices',
            body: requestBody,
            mediaType: 'application/json',
            errors: {
                400: `bad request`,
                401: `unauthorized`,
            },
        });
    }
}
