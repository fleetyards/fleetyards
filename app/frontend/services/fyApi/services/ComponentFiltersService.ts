/* generated using openapi-typescript-codegen -- do not edit */
/* istanbul ignore file */
/* tslint:disable */
/* eslint-disable */
import type { FilterOption } from '../models/FilterOption';
import type { CancelablePromise } from '../core/CancelablePromise';
import type { BaseHttpRequest } from '../core/BaseHttpRequest';
export class ComponentFiltersService {
    constructor(public readonly httpRequest: BaseHttpRequest) {}
    /**
     * Commodity Types
     * @returns FilterOption successful
     * @throws ApiError
     */
    public componentClasses(): CancelablePromise<Array<FilterOption>> {
        return this.httpRequest.request({
            method: 'GET',
            url: '/filters/components/classes',
        });
    }
    /**
     * Commodity Types
     * @returns FilterOption successful
     * @throws ApiError
     */
    public componentItemTypes(): CancelablePromise<Array<FilterOption>> {
        return this.httpRequest.request({
            method: 'GET',
            url: '/filters/components/item-types',
        });
    }
}
