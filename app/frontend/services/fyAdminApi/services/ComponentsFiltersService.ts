/* generated using openapi-typescript-codegen -- do not edit */
/* istanbul ignore file */
/* tslint:disable */
/* eslint-disable */
import type { FilterOption } from '../models/FilterOption';
import type { CancelablePromise } from '../core/CancelablePromise';
import type { BaseHttpRequest } from '../core/BaseHttpRequest';
export class ComponentsFiltersService {
    constructor(public readonly httpRequest: BaseHttpRequest) {}
    /**
     * Component Item Type Filters
     * Get a list of Component Item Types
     * @returns FilterOption successful
     * @throws ApiError
     */
    public itemTypes(): CancelablePromise<Array<FilterOption>> {
        return this.httpRequest.request({
            method: 'GET',
            url: '/components/item_type_filters',
            errors: {
                401: `unauthorized`,
            },
        });
    }
}
