/* generated using openapi-typescript-codegen -- do no edit */
/* istanbul ignore file */
/* tslint:disable */
/* eslint-disable */
import type { ComponentMinimal } from '../models/ComponentMinimal';
import type { FilterOption } from '../models/FilterOption';

import type { CancelablePromise } from '../core/CancelablePromise';
import type { BaseHttpRequest } from '../core/BaseHttpRequest';

export class ComponentsService {

    constructor(public readonly httpRequest: BaseHttpRequest) {}

    /**
     * list components
     * Get a List of Components
     * @returns ComponentMinimal successful
     * @throws ApiError
     */
    public getComponents(): CancelablePromise<Array<ComponentMinimal>> {
        return this.httpRequest.request({
            method: 'GET',
            url: '/components',
        });
    }

    /**
     * class_filters component
     * Get a List of all Component Classes
     * @returns FilterOption successful
     * @throws ApiError
     */
    public getComponentsClassFilters(): CancelablePromise<Array<FilterOption>> {
        return this.httpRequest.request({
            method: 'GET',
            url: '/components/class_filters',
        });
    }

    /**
     * item_type_filters component
     * Get a List of all Component Item Types
     * @returns FilterOption successful
     * @throws ApiError
     */
    public getComponentsItemTypeFilters(): CancelablePromise<Array<FilterOption>> {
        return this.httpRequest.request({
            method: 'GET',
            url: '/components/item_type_filters',
        });
    }

}
