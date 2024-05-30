/* generated using openapi-typescript-codegen -- do not edit */
/* istanbul ignore file */
/* tslint:disable */
/* eslint-disable */
import type { ItemPrice } from '../models/ItemPrice';
import type { ItemPriceInput } from '../models/ItemPriceInput';
import type { ItemPriceQuery } from '../models/ItemPriceQuery';
import type { ItemPrices } from '../models/ItemPrices';
import type { CancelablePromise } from '../core/CancelablePromise';
import type { BaseHttpRequest } from '../core/BaseHttpRequest';
export class ItemPricesService {
    constructor(public readonly httpRequest: BaseHttpRequest) {}
    /**
     * Create new Item Price
     * @returns ItemPrice successful
     * @throws ApiError
     */
    public createItemPrice({
        requestBody,
    }: {
        requestBody: ItemPriceInput,
    }): CancelablePromise<ItemPrice> {
        return this.httpRequest.request({
            method: 'POST',
            url: '/item-prices',
            body: requestBody,
            mediaType: 'application/json',
            errors: {
                400: `unauthorized`,
                401: `unauthorized`,
            },
        });
    }
    /**
     * Item Prices list
     * @returns ItemPrices successful
     * @throws ApiError
     */
    public itemPrices({
        page = '1',
        perPage = '25',
        s,
        q,
    }: {
        page?: string,
        perPage?: string,
        /**
         * Sorting
         */
        s?: Array<string>,
        q?: ItemPriceQuery,
    }): CancelablePromise<ItemPrices> {
        return this.httpRequest.request({
            method: 'GET',
            url: '/item-prices',
            query: {
                'page': page,
                'perPage': perPage,
                's': s,
                'q': q,
            },
            errors: {
                401: `unauthorized`,
            },
        });
    }
    /**
     * Item price destroy
     * @returns void
     * @throws ApiError
     */
    public destroyItemPrice({
        id,
    }: {
        /**
         * id
         */
        id: string,
    }): CancelablePromise<void> {
        return this.httpRequest.request({
            method: 'DELETE',
            url: '/item-prices/{id}',
            path: {
                'id': id,
            },
            errors: {
                401: `unauthorized`,
                404: `not_found`,
            },
        });
    }
    /**
     * Get Item Price
     * @returns ItemPrice successful
     * @throws ApiError
     */
    public itemPrice({
        id,
    }: {
        /**
         * id
         */
        id: string,
    }): CancelablePromise<ItemPrice> {
        return this.httpRequest.request({
            method: 'GET',
            url: '/item-prices/{id}',
            path: {
                'id': id,
            },
            errors: {
                401: `unauthorized`,
                404: `not found`,
            },
        });
    }
    /**
     * Update Item Price
     * @returns ItemPrice successful
     * @throws ApiError
     */
    public updateItemPrice({
        id,
        requestBody,
    }: {
        /**
         * id
         */
        id: string,
        requestBody: ItemPriceInput,
    }): CancelablePromise<ItemPrice> {
        return this.httpRequest.request({
            method: 'PUT',
            url: '/item-prices/{id}',
            path: {
                'id': id,
            },
            body: requestBody,
            mediaType: 'application/json',
            errors: {
                400: `unauthorized`,
                401: `unauthorized`,
                404: `not found`,
            },
        });
    }
}
