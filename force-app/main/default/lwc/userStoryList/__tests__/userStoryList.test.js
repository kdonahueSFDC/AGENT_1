/**
 * @description Jest unit tests for userStoryList LWC component
 * @author Salesforce (Cursor)
 * @date 2025-12-08
 */

import { createElement } from 'lwc';
import { flushPromises } from '@salesforce/sfdx-lwc-jest';
import UserStoryList from 'c/userStoryList';
import getUserStories from '@salesforce/apex/UserStoryController.getUserStories';
import getFeatures from '@salesforce/apex/UserStoryController.getFeatures';

// Mock Apex methods
jest.mock(
    '@salesforce/apex/UserStoryController.getUserStories',
    () => {
        return {
            default: jest.fn()
        };
    },
    { virtual: true }
);

jest.mock(
    '@salesforce/apex/UserStoryController.getFeatures',
    () => {
        return {
            default: jest.fn()
        };
    },
    { virtual: true }
);

// Mock ShowToastEvent
const mockShowToastEvent = jest.fn();
jest.mock('lightning/platformShowToastEvent', () => {
    return {
        ShowToastEvent: jest.fn().mockImplementation(() => {
            return {
                dispatchEvent: mockShowToastEvent
            };
        })
    };
});

describe('c-userStoryList', () => {
    afterEach(() => {
        // Clear mocks after each test
        jest.clearAllMocks();
        while (document.body.firstChild) {
            document.body.removeChild(document.body.firstChild);
        }
    });

    // Helper function to create component element
    function createComponent() {
        const element = createElement('c-userStoryList', {
            is: UserStoryList
        });
        document.body.appendChild(element);
        return element;
    }

    // Mock data helpers
    function createMockFeature(id, name) {
        return {
            id: id || 'a0X000000000001AAA',
            name: name || 'Test Feature',
            status: 'In Progress',
            description: 'Test Description'
        };
    }

    function createMockUserStory(id, name, status, priority, featureId, assigneeId) {
        return {
            id: id || 'a0Y000000000001AAA',
            name: name || 'Test Story',
            description: 'Test Description',
            status: status || 'Backlog',
            priority: priority || 'Medium',
            assigneeId: assigneeId || null,
            assigneeName: assigneeId ? 'Test User' : null,
            featureId: featureId || 'a0X000000000001AAA',
            featureName: 'Test Feature',
            acceptanceCriteria: 'Test Criteria',
            createdDate: '2025-01-01T00:00:00.000Z',
            lastModifiedDate: '2025-01-01T00:00:00.000Z'
        };
    }

    function createMockPaginatedResult(records, totalRecords, totalPages, currentPage, pageSize) {
        return {
            records: records || [],
            totalRecords: totalRecords || 0,
            totalPages: totalPages || 0,
            currentPage: currentPage || 1,
            pageSize: pageSize || 25
        };
    }

    describe('Component Initialization', () => {
        it('renders component without errors', () => {
            const element = createComponent();
            expect(element).toBeTruthy();
        });

        it('sets isLoading to true on connectedCallback', () => {
            const element = createComponent();
            expect(element.isLoading).toBe(true);
        });

        it('initializes with default values', () => {
            const element = createComponent();
            expect(element.selectedFeatureId).toBe('');
            expect(element.selectedStatus).toBe('');
            expect(element.selectedPriority).toBe('');
            expect(element.currentPage).toBe(1);
            expect(element.pageSize).toBe(25);
            expect(element.sortBy).toBe('Name');
            expect(element.sortDirection).toBe('asc');
        });

        it('loads features on initialization', async () => {
            const mockFeatures = [
                createMockFeature('a0X000000000001AAA', 'Feature A'),
                createMockFeature('a0X000000000002AAA', 'Feature B')
            ];

            getFeatures.mockResolvedValue(mockFeatures);

            const element = createComponent();
            await flushPromises();

            expect(getFeatures).toHaveBeenCalled();
            expect(element.features.length).toBe(2);
            expect(element.featureOptions.length).toBe(3); // Includes "All Features" option
            expect(element.featureOptions[0].label).toBe('All Features');
            expect(element.featureOptions[0].value).toBe('');
        });
    });

    describe('Feature Filtering', () => {
        it('updates selectedFeatureId when feature filter changes', async () => {
            const mockFeatures = [createMockFeature('a0X000000000001AAA', 'Feature A')];
            const mockResult = createMockPaginatedResult(
                [createMockUserStory('a0Y000000000001AAA', 'Story 1', 'Backlog', 'High', 'a0X000000000001AAA')],
                1,
                1,
                1,
                25
            );

            getFeatures.mockResolvedValue(mockFeatures);
            getUserStories.mockResolvedValue(mockResult);

            const element = createComponent();
            await flushPromises();

            const featureCombobox = element.shadowRoot.querySelector('lightning-combobox[label="Feature"]');
            expect(featureCombobox).toBeTruthy();

            // Simulate feature selection
            featureCombobox.value = 'a0X000000000001AAA';
            featureCombobox.dispatchEvent(new CustomEvent('change', {
                detail: { value: 'a0X000000000001AAA' }
            }));

            await flushPromises();

            expect(element.selectedFeatureId).toBe('a0X000000000001AAA');
        });

        it('resets to page 1 when feature filter changes', async () => {
            const mockFeatures = [createMockFeature('a0X000000000001AAA', 'Feature A')];
            const mockResult = createMockPaginatedResult(
                [createMockUserStory('a0Y000000000001AAA', 'Story 1')],
                1,
                1,
                1,
                25
            );

            getFeatures.mockResolvedValue(mockFeatures);
            getUserStories.mockResolvedValue(mockResult);

            const element = createComponent();
            await flushPromises();

            // Set to page 2
            element.currentPage = 2;
            await flushPromises();

            // Change feature filter
            element.handleFeatureChange({
                detail: { value: 'a0X000000000001AAA' }
            });

            expect(element.currentPage).toBe(1);
        });

        it('clears feature filter when "All Features" is selected', async () => {
            const mockFeatures = [createMockFeature('a0X000000000001AAA', 'Feature A')];
            const mockResult = createMockPaginatedResult([], 0, 0, 1, 25);

            getFeatures.mockResolvedValue(mockFeatures);
            getUserStories.mockResolvedValue(mockResult);

            const element = createComponent();
            await flushPromises();

            element.selectedFeatureId = 'a0X000000000001AAA';
            await flushPromises();

            element.handleFeatureChange({
                detail: { value: '' }
            });

            expect(element.selectedFeatureId).toBe('');
        });
    });

    describe('Status Filtering', () => {
        it('updates selectedStatus when status filter changes', async () => {
            const mockFeatures = [];
            const mockResult = createMockPaginatedResult([], 0, 0, 1, 25);

            getFeatures.mockResolvedValue(mockFeatures);
            getUserStories.mockResolvedValue(mockResult);

            const element = createComponent();
            await flushPromises();

            element.handleStatusChange({
                detail: { value: 'In_Progress' }
            });

            expect(element.selectedStatus).toBe('In_Progress');
        });

        it('resets to page 1 when status filter changes', async () => {
            const mockFeatures = [];
            const mockResult = createMockPaginatedResult([], 0, 0, 1, 25);

            getFeatures.mockResolvedValue(mockFeatures);
            getUserStories.mockResolvedValue(mockResult);

            const element = createComponent();
            await flushPromises();

            element.currentPage = 2;
            element.handleStatusChange({
                detail: { value: 'Backlog' }
            });

            expect(element.currentPage).toBe(1);
        });

        it('handles all status options correctly', async () => {
            const mockFeatures = [];
            const mockResult = createMockPaginatedResult([], 0, 0, 1, 25);

            getFeatures.mockResolvedValue(mockFeatures);
            getUserStories.mockResolvedValue(mockResult);

            const element = createComponent();
            await flushPromises();

            const statuses = ['Backlog', 'In_Progress', 'In_Review', 'Done', 'Blocked'];
            statuses.forEach(status => {
                element.handleStatusChange({
                    detail: { value: status }
                });
                expect(element.selectedStatus).toBe(status);
            });
        });
    });

    describe('Priority Filtering', () => {
        it('updates selectedPriority when priority filter changes', async () => {
            const mockFeatures = [];
            const mockResult = createMockPaginatedResult([], 0, 0, 1, 25);

            getFeatures.mockResolvedValue(mockFeatures);
            getUserStories.mockResolvedValue(mockResult);

            const element = createComponent();
            await flushPromises();

            element.handlePriorityChange({
                detail: { value: 'High' }
            });

            expect(element.selectedPriority).toBe('High');
        });

        it('resets to page 1 when priority filter changes', async () => {
            const mockFeatures = [];
            const mockResult = createMockPaginatedResult([], 0, 0, 1, 25);

            getFeatures.mockResolvedValue(mockFeatures);
            getUserStories.mockResolvedValue(mockResult);

            const element = createComponent();
            await flushPromises();

            element.currentPage = 2;
            element.handlePriorityChange({
                detail: { value: 'Critical' }
            });

            expect(element.currentPage).toBe(1);
        });

        it('handles all priority options correctly', async () => {
            const mockFeatures = [];
            const mockResult = createMockPaginatedResult([], 0, 0, 1, 25);

            getFeatures.mockResolvedValue(mockFeatures);
            getUserStories.mockResolvedValue(mockResult);

            const element = createComponent();
            await flushPromises();

            const priorities = ['Low', 'Medium', 'High', 'Critical'];
            priorities.forEach(priority => {
                element.handlePriorityChange({
                    detail: { value: priority }
                });
                expect(element.selectedPriority).toBe(priority);
            });
        });
    });

    describe('Clear Filters', () => {
        it('clears all filters when handleClearFilters is called', async () => {
            const mockFeatures = [];
            const mockResult = createMockPaginatedResult([], 0, 0, 1, 25);

            getFeatures.mockResolvedValue(mockFeatures);
            getUserStories.mockResolvedValue(mockResult);

            const element = createComponent();
            await flushPromises();

            // Set filters
            element.selectedFeatureId = 'a0X000000000001AAA';
            element.selectedStatus = 'In_Progress';
            element.selectedPriority = 'High';
            element.assigneeId = '005000000000001AAA';

            // Clear filters
            element.handleClearFilters();

            expect(element.selectedFeatureId).toBe('');
            expect(element.selectedStatus).toBe('');
            expect(element.selectedPriority).toBe('');
            expect(element.assigneeId).toBe('');
        });

        it('resets to page 1 when filters are cleared', async () => {
            const mockFeatures = [];
            const mockResult = createMockPaginatedResult([], 0, 0, 1, 25);

            getFeatures.mockResolvedValue(mockFeatures);
            getUserStories.mockResolvedValue(mockResult);

            const element = createComponent();
            await flushPromises();

            element.currentPage = 3;
            element.handleClearFilters();

            expect(element.currentPage).toBe(1);
        });

        it('shows clear filters button when filters are active', async () => {
            const mockFeatures = [];
            const mockResult = createMockPaginatedResult([], 0, 0, 1, 25);

            getFeatures.mockResolvedValue(mockFeatures);
            getUserStories.mockResolvedValue(mockResult);

            const element = createComponent();
            await flushPromises();

            // Initially no filters
            element.selectedFeatureId = '';
            await flushPromises();
            let clearButton = element.shadowRoot.querySelector('lightning-button[label="Clear Filters"]');
            expect(clearButton).toBeFalsy();

            // Set a filter
            element.selectedFeatureId = 'a0X000000000001AAA';
            await flushPromises();
            clearButton = element.shadowRoot.querySelector('lightning-button[label="Clear Filters"]');
            expect(clearButton).toBeTruthy();
        });
    });

    describe('Pagination', () => {
        it('increments page when handleNext is called', async () => {
            const mockFeatures = [];
            const mockResult = createMockPaginatedResult(
                [createMockUserStory('a0Y000000000001AAA', 'Story 1')],
                10,
                2,
                1,
                5
            );

            getFeatures.mockResolvedValue(mockFeatures);
            getUserStories.mockResolvedValue(mockResult);

            const element = createComponent();
            await flushPromises();

            expect(element.currentPage).toBe(1);
            element.handleNext();
            expect(element.currentPage).toBe(2);
        });

        it('decrements page when handlePrevious is called', async () => {
            const mockFeatures = [];
            const mockResult = createMockPaginatedResult(
                [createMockUserStory('a0Y000000000001AAA', 'Story 1')],
                10,
                2,
                2,
                5
            );

            getFeatures.mockResolvedValue(mockFeatures);
            getUserStories.mockResolvedValue(mockResult);

            const element = createComponent();
            element.currentPage = 2;
            await flushPromises();

            element.handlePrevious();
            expect(element.currentPage).toBe(1);
        });

        it('disables previous button on first page', async () => {
            const mockFeatures = [];
            const mockResult = createMockPaginatedResult(
                [createMockUserStory('a0Y000000000001AAA', 'Story 1')],
                5,
                1,
                1,
                5
            );

            getFeatures.mockResolvedValue(mockFeatures);
            getUserStories.mockResolvedValue(mockResult);

            const element = createComponent();
            await flushPromises();

            expect(element.isPreviousDisabled).toBe(true);
        });

        it('disables next button on last page', async () => {
            const mockFeatures = [];
            const mockResult = createMockPaginatedResult(
                [createMockUserStory('a0Y000000000001AAA', 'Story 1')],
                5,
                1,
                1,
                5
            );

            getFeatures.mockResolvedValue(mockFeatures);
            getUserStories.mockResolvedValue(mockResult);

            const element = createComponent();
            await flushPromises();

            expect(element.isNextDisabled).toBe(true);
        });

        it('enables navigation buttons when appropriate', async () => {
            const mockFeatures = [];
            const mockResult = createMockPaginatedResult(
                [createMockUserStory('a0Y000000000001AAA', 'Story 1')],
                10,
                2,
                1,
                5
            );

            getFeatures.mockResolvedValue(mockFeatures);
            getUserStories.mockResolvedValue(mockResult);

            const element = createComponent();
            await flushPromises();

            expect(element.isPreviousDisabled).toBe(true); // On first page
            expect(element.isNextDisabled).toBe(false); // Not on last page
        });

        it('displays correct page info', async () => {
            const mockFeatures = [];
            const mockResult = createMockPaginatedResult(
                [createMockUserStory('a0Y000000000001AAA', 'Story 1')],
                10,
                2,
                1,
                5
            );

            getFeatures.mockResolvedValue(mockFeatures);
            getUserStories.mockResolvedValue(mockResult);

            const element = createComponent();
            await flushPromises();

            expect(element.pageInfo).toBe('Showing 1-5 of 10 user stories');
        });

        it('displays correct page info for last page', async () => {
            const mockFeatures = [];
            const mockResult = createMockPaginatedResult(
                [createMockUserStory('a0Y000000000001AAA', 'Story 1')],
                10,
                2,
                2,
                5
            );

            getFeatures.mockResolvedValue(mockFeatures);
            getUserStories.mockResolvedValue(mockResult);

            const element = createComponent();
            element.currentPage = 2;
            await flushPromises();

            expect(element.pageInfo).toBe('Showing 6-10 of 10 user stories');
        });

        it('displays "No user stories found" when totalRecords is 0', async () => {
            const mockFeatures = [];
            const mockResult = createMockPaginatedResult([], 0, 0, 1, 25);

            getFeatures.mockResolvedValue(mockFeatures);
            getUserStories.mockResolvedValue(mockResult);

            const element = createComponent();
            await flushPromises();

            expect(element.pageInfo).toBe('No user stories found');
        });

        it('sets isLoading when navigating pages', async () => {
            const mockFeatures = [];
            const mockResult = createMockPaginatedResult(
                [createMockUserStory('a0Y000000000001AAA', 'Story 1')],
                10,
                2,
                1,
                5
            );

            getFeatures.mockResolvedValue(mockFeatures);
            getUserStories.mockResolvedValue(mockResult);

            const element = createComponent();
            await flushPromises();

            expect(element.isLoading).toBe(false);
            element.handleNext();
            expect(element.isLoading).toBe(true);
        });
    });

    describe('Sorting', () => {
        it('updates sortBy and sortDirection when handleSort is called', async () => {
            const mockFeatures = [];
            const mockResult = createMockPaginatedResult(
                [createMockUserStory('a0Y000000000001AAA', 'Story 1')],
                1,
                1,
                1,
                25
            );

            getFeatures.mockResolvedValue(mockFeatures);
            getUserStories.mockResolvedValue(mockResult);

            const element = createComponent();
            await flushPromises();

            element.handleSort({
                detail: {
                    fieldName: 'status',
                    sortDirection: 'desc'
                }
            });

            expect(element.sortBy).toBe('Status__c');
            expect(element.sortDirection).toBe('desc');
        });

        it('maps datatable field names to Apex field names correctly', async () => {
            const mockFeatures = [];
            const mockResult = createMockPaginatedResult(
                [createMockUserStory('a0Y000000000001AAA', 'Story 1')],
                1,
                1,
                1,
                25
            );

            getFeatures.mockResolvedValue(mockFeatures);
            getUserStories.mockResolvedValue(mockResult);

            const element = createComponent();
            await flushPromises();

            const fieldMappings = {
                'name': 'Name',
                'featureName': 'Feature__r.Name',
                'status': 'Status__c',
                'priority': 'Priority__c',
                'assigneeName': 'Assignee__r.Name',
                'createdDate': 'CreatedDate'
            };

            Object.keys(fieldMappings).forEach(datatableField => {
                element.handleSort({
                    detail: {
                        fieldName: datatableField,
                        sortDirection: 'asc'
                    }
                });
                expect(element.sortBy).toBe(fieldMappings[datatableField]);
            });
        });

        it('defaults to Name when invalid field is provided', async () => {
            const mockFeatures = [];
            const mockResult = createMockPaginatedResult(
                [createMockUserStory('a0Y000000000001AAA', 'Story 1')],
                1,
                1,
                1,
                25
            );

            getFeatures.mockResolvedValue(mockFeatures);
            getUserStories.mockResolvedValue(mockResult);

            const element = createComponent();
            await flushPromises();

            element.handleSort({
                detail: {
                    fieldName: 'InvalidField',
                    sortDirection: 'asc'
                }
            });

            expect(element.sortBy).toBe('Name');
        });

        it('resets to page 1 when sorting changes', async () => {
            const mockFeatures = [];
            const mockResult = createMockPaginatedResult(
                [createMockUserStory('a0Y000000000001AAA', 'Story 1')],
                1,
                1,
                1,
                25
            );

            getFeatures.mockResolvedValue(mockFeatures);
            getUserStories.mockResolvedValue(mockResult);

            const element = createComponent();
            await flushPromises();

            element.currentPage = 3;
            element.handleSort({
                detail: {
                    fieldName: 'status',
                    sortDirection: 'desc'
                }
            });

            expect(element.currentPage).toBe(1);
        });

        it('sets isLoading when sorting changes', async () => {
            const mockFeatures = [];
            const mockResult = createMockPaginatedResult(
                [createMockUserStory('a0Y000000000001AAA', 'Story 1')],
                1,
                1,
                1,
                25
            );

            getFeatures.mockResolvedValue(mockFeatures);
            getUserStories.mockResolvedValue(mockResult);

            const element = createComponent();
            await flushPromises();

            expect(element.isLoading).toBe(false);
            element.handleSort({
                detail: {
                    fieldName: 'name',
                    sortDirection: 'asc'
                }
            });
            expect(element.isLoading).toBe(true);
        });
    });

    describe('Data Display', () => {
        it('displays user stories in datatable', async () => {
            const mockFeatures = [];
            const mockStories = [
                createMockUserStory('a0Y000000000001AAA', 'Story 1', 'Backlog', 'High'),
                createMockUserStory('a0Y000000000002AAA', 'Story 2', 'In_Progress', 'Critical')
            ];
            const mockResult = createMockPaginatedResult(mockStories, 2, 1, 1, 25);

            getFeatures.mockResolvedValue(mockFeatures);
            getUserStories.mockResolvedValue(mockResult);

            const element = createComponent();
            await flushPromises();

            expect(element.userStories.length).toBe(2);
            expect(element.userStories[0].name).toBe('Story 1');
            expect(element.userStories[1].name).toBe('Story 2');
        });

        it('formats record links correctly', async () => {
            const mockFeatures = [];
            const mockStory = createMockUserStory('a0Y000000000001AAA', 'Story 1');
            const mockResult = createMockPaginatedResult([mockStory], 1, 1, 1, 25);

            getFeatures.mockResolvedValue(mockFeatures);
            getUserStories.mockResolvedValue(mockResult);

            const element = createComponent();
            await flushPromises();

            expect(element.userStories[0].recordLink).toBe('/a0Y000000000001AAA');
        });

        it('applies correct status CSS classes', async () => {
            const mockFeatures = [];
            const mockStories = [
                createMockUserStory('a0Y000000000001AAA', 'Story 1', 'Backlog'),
                createMockUserStory('a0Y000000000002AAA', 'Story 2', 'In_Progress'),
                createMockUserStory('a0Y000000000003AAA', 'Story 3', 'Blocked')
            ];
            const mockResult = createMockPaginatedResult(mockStories, 3, 1, 1, 25);

            getFeatures.mockResolvedValue(mockFeatures);
            getUserStories.mockResolvedValue(mockResult);

            const element = createComponent();
            await flushPromises();

            expect(element.userStories[0].statusClass).toBe('slds-text-color_default');
            expect(element.userStories[1].statusClass).toBe('slds-text-color_success');
            expect(element.userStories[2].statusClass).toBe('slds-text-color_error');
        });

        it('applies correct priority CSS classes', async () => {
            const mockFeatures = [];
            const mockStories = [
                createMockUserStory('a0Y000000000001AAA', 'Story 1', 'Backlog', 'Low'),
                createMockUserStory('a0Y000000000002AAA', 'Story 2', 'Backlog', 'High'),
                createMockUserStory('a0Y000000000003AAA', 'Story 3', 'Backlog', 'Critical')
            ];
            const mockResult = createMockPaginatedResult(mockStories, 3, 1, 1, 25);

            getFeatures.mockResolvedValue(mockFeatures);
            getUserStories.mockResolvedValue(mockResult);

            const element = createComponent();
            await flushPromises();

            expect(element.userStories[0].priorityClass).toBe('slds-text-color_default');
            expect(element.userStories[1].priorityClass).toBe('slds-text-color_warning');
            expect(element.userStories[2].priorityClass).toBe('slds-text-color_error');
        });

        it('formats status labels correctly', async () => {
            const mockFeatures = [];
            const mockStories = [
                createMockUserStory('a0Y000000000001AAA', 'Story 1', 'In_Progress'),
                createMockUserStory('a0Y000000000002AAA', 'Story 2', 'In_Review')
            ];
            const mockResult = createMockPaginatedResult(mockStories, 2, 1, 1, 25);

            getFeatures.mockResolvedValue(mockFeatures);
            getUserStories.mockResolvedValue(mockResult);

            const element = createComponent();
            await flushPromises();

            expect(element.userStories[0].statusLabel).toBe('In Progress');
            expect(element.userStories[1].statusLabel).toBe('In Review');
        });

        it('handles empty data gracefully', async () => {
            const mockFeatures = [];
            const mockResult = createMockPaginatedResult([], 0, 0, 1, 25);

            getFeatures.mockResolvedValue(mockFeatures);
            getUserStories.mockResolvedValue(mockResult);

            const element = createComponent();
            await flushPromises();

            expect(element.userStories.length).toBe(0);
            expect(element.totalRecords).toBe(0);
        });
    });

    describe('Error Handling', () => {
        it('displays error toast when getUserStories fails', async () => {
            const mockFeatures = [];
            const mockError = {
                body: {
                    message: 'Test error message'
                }
            };

            getFeatures.mockResolvedValue(mockFeatures);
            getUserStories.mockRejectedValue(mockError);

            const element = createComponent();
            await flushPromises();

            expect(mockShowToastEvent).toHaveBeenCalled();
            expect(element.error).toBeTruthy();
        });

        it('displays error toast when getFeatures fails', async () => {
            const mockError = {
                body: {
                    message: 'Test error message'
                }
            };

            getFeatures.mockRejectedValue(mockError);

            const element = createComponent();
            await flushPromises();

            expect(mockShowToastEvent).toHaveBeenCalled();
            expect(element.error).toBeTruthy();
        });

        it('handles error without body message', async () => {
            const mockFeatures = [];
            const mockError = {};

            getFeatures.mockResolvedValue(mockFeatures);
            getUserStories.mockRejectedValue(mockError);

            const element = createComponent();
            await flushPromises();

            expect(mockShowToastEvent).toHaveBeenCalled();
        });

        it('clears user stories on error', async () => {
            const mockFeatures = [];
            const mockError = {
                body: {
                    message: 'Test error'
                }
            };

            getFeatures.mockResolvedValue(mockFeatures);
            getUserStories.mockRejectedValue(mockError);

            const element = createComponent();
            await flushPromises();

            expect(element.userStories.length).toBe(0);
        });
    });

    describe('Computed Properties', () => {
        it('hasFilters returns true when filters are active', async () => {
            const mockFeatures = [];
            const mockResult = createMockPaginatedResult([], 0, 0, 1, 25);

            getFeatures.mockResolvedValue(mockFeatures);
            getUserStories.mockResolvedValue(mockResult);

            const element = createComponent();
            await flushPromises();

            element.selectedFeatureId = 'a0X000000000001AAA';
            expect(element.hasFilters).toBe(true);

            element.selectedFeatureId = '';
            element.selectedStatus = 'Backlog';
            expect(element.hasFilters).toBe(true);

            element.selectedStatus = '';
            element.selectedPriority = 'High';
            expect(element.hasFilters).toBe(true);

            element.selectedPriority = '';
            element.assigneeId = '005000000000001AAA';
            expect(element.hasFilters).toBe(true);
        });

        it('hasFilters returns false when no filters are active', async () => {
            const mockFeatures = [];
            const mockResult = createMockPaginatedResult([], 0, 0, 1, 25);

            getFeatures.mockResolvedValue(mockFeatures);
            getUserStories.mockResolvedValue(mockResult);

            const element = createComponent();
            await flushPromises();

            expect(element.hasFilters).toBe(false);
        });

        it('isPreviousDisabled returns true when on first page', async () => {
            const mockFeatures = [];
            const mockResult = createMockPaginatedResult(
                [createMockUserStory('a0Y000000000001AAA', 'Story 1')],
                5,
                1,
                1,
                5
            );

            getFeatures.mockResolvedValue(mockFeatures);
            getUserStories.mockResolvedValue(mockResult);

            const element = createComponent();
            await flushPromises();

            expect(element.isPreviousDisabled).toBe(true);
        });

        it('isPreviousDisabled returns true when isLoading', async () => {
            const mockFeatures = [];
            const mockResult = createMockPaginatedResult(
                [createMockUserStory('a0Y000000000001AAA', 'Story 1')],
                10,
                2,
                2,
                5
            );

            getFeatures.mockResolvedValue(mockFeatures);
            getUserStories.mockResolvedValue(mockResult);

            const element = createComponent();
            element.currentPage = 2;
            element.isLoading = true;
            await flushPromises();

            expect(element.isPreviousDisabled).toBe(true);
        });

        it('isNextDisabled returns true when on last page', async () => {
            const mockFeatures = [];
            const mockResult = createMockPaginatedResult(
                [createMockUserStory('a0Y000000000001AAA', 'Story 1')],
                5,
                1,
                1,
                5
            );

            getFeatures.mockResolvedValue(mockFeatures);
            getUserStories.mockResolvedValue(mockResult);

            const element = createComponent();
            await flushPromises();

            expect(element.isNextDisabled).toBe(true);
        });

        it('isNextDisabled returns true when isLoading', async () => {
            const mockFeatures = [];
            const mockResult = createMockPaginatedResult(
                [createMockUserStory('a0Y000000000001AAA', 'Story 1')],
                10,
                2,
                1,
                5
            );

            getFeatures.mockResolvedValue(mockFeatures);
            getUserStories.mockResolvedValue(mockResult);

            const element = createComponent();
            element.isLoading = true;
            await flushPromises();

            expect(element.isNextDisabled).toBe(true);
        });
    });

    describe('Wire Adapter Reactivity', () => {
        it('refetches data when selectedFeatureId changes', async () => {
            const mockFeatures = [];
            const mockResult = createMockPaginatedResult([], 0, 0, 1, 25);

            getFeatures.mockResolvedValue(mockFeatures);
            getUserStories.mockResolvedValue(mockResult);

            const element = createComponent();
            await flushPromises();

            const initialCallCount = getUserStories.mock.calls.length;

            element.selectedFeatureId = 'a0X000000000001AAA';
            await flushPromises();

            expect(getUserStories.mock.calls.length).toBeGreaterThan(initialCallCount);
        });

        it('refetches data when selectedStatus changes', async () => {
            const mockFeatures = [];
            const mockResult = createMockPaginatedResult([], 0, 0, 1, 25);

            getFeatures.mockResolvedValue(mockFeatures);
            getUserStories.mockResolvedValue(mockResult);

            const element = createComponent();
            await flushPromises();

            const initialCallCount = getUserStories.mock.calls.length;

            element.selectedStatus = 'Backlog';
            await flushPromises();

            expect(getUserStories.mock.calls.length).toBeGreaterThan(initialCallCount);
        });

        it('refetches data when pagination changes', async () => {
            const mockFeatures = [];
            const mockResult = createMockPaginatedResult(
                [createMockUserStory('a0Y000000000001AAA', 'Story 1')],
                10,
                2,
                1,
                5
            );

            getFeatures.mockResolvedValue(mockFeatures);
            getUserStories.mockResolvedValue(mockResult);

            const element = createComponent();
            await flushPromises();

            const initialCallCount = getUserStories.mock.calls.length;

            element.currentPage = 2;
            await flushPromises();

            expect(getUserStories.mock.calls.length).toBeGreaterThan(initialCallCount);
        });
    });
});

