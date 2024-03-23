/* generated using openapi-typescript-codegen -- do not edit */
/* istanbul ignore file */
/* tslint:disable */
/* eslint-disable */
import type { ComponentQuery } from '../models/ComponentQuery';
import type { Components } from '../models/Components';
import type { FilterOption } from '../models/FilterOption';
import type { CancelablePromise } from '../core/CancelablePromise';
import type { BaseHttpRequest } from '../core/BaseHttpRequest';
export class ComponentsService {
    constructor(public readonly httpRequest: BaseHttpRequest) {}
    /**
     * @deprecated
     * Commodity Types
     * @returns FilterOption successful
     * @throws ApiError
     */
    public deprecateDcomponentClasses(): CancelablePromise<Array<FilterOption>> {
        return this.httpRequest.request({
            method: 'GET',
            url: '/components/class_filters',
        });
    }
    /**
     * @deprecated
     * Commodity Types
     * @returns FilterOption successful
     * @throws ApiError
     */
    public deprecateDcomponentItemTypes(): CancelablePromise<Array<FilterOption>> {
        return this.httpRequest.request({
            method: 'GET',
            url: '/components/item_type_filters',
        });
    }
    /**
     * Components list
     * @returns Components successful
     * @throws ApiError
     */
    public components({
        page = '1',
        perPage = '50',
        q,
        cacheId,
    }: {
        page?: string,
        perPage?: string,
        q?: ComponentQuery,
        cacheId?: string,
    }): CancelablePromise<Components> {
        return this.httpRequest.request({
            method: 'GET',
            url: '/components',
            query: {
                'page': page,
                'perPage': perPage,
                'q': q,
                'cacheId': cacheId,
            },
        });
    }
}
