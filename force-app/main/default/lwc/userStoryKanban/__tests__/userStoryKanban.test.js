/**
 * @description Jest unit tests for userStoryKanban LWC component
 * @author Salesforce (Cursor)
 * @date 2025-12-08
 */

import { createElement } from 'lwc';
import { flushPromises } from '@salesforce/sfdx-lwc-jest';
import UserStoryKanban from 'c/userStoryKanban';
import getUserStoriesByStatus from '@salesforce/apex/UserStoryController.getUserStoriesByStatus';
import updateUserStoryStatus from '@salesforce/apex/UserStoryController.updateUserStoryStatus';
import getFeatures from '@salesforce/apex/UserStoryController.getFeatures';

// Mock Apex methods
jest.mock(
    '@salesforce/apex/UserStoryController.getUserStoriesByStatus',
    () => {
        return {
            default: jest.fn()
        };
    },
    { virtual: true }
);

jest.mock(
    '@salesforce/apex/UserStoryController.updateUserStoryStatus',
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
        ShowToastEvent: jest.fn().mockImplementation((config) => {
            return {
                title: config.title,
                message: config.message,
                variant: config.variant,
                mode: config.mode,
                dispatchEvent: mockShowToastEvent
            };
        })
    };
});

// Mock NavigationMixin
const mockNavigate = jest.fn();
jest.mock('lightning/navigation', () => {
    return {
        NavigationMixin: (Base) => {
            return class extends Base {
                [Symbol.for('lightning-navigation')] = {
                    Navigate: mockNavigate
                };
            };
        }
    };
});

describe('c-userStoryKanban', () => {
    afterEach(() => {
        // Clear mocks after each test
        jest.clearAllMocks();
        while (document.body.firstChild) {
            document.body.removeChild(document.body.firstChild);
        }
    });

    // Helper function to create component element
    function createComponent() {
        const element = createElement('c-userStoryKanban', {
            is: UserStoryKanban
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

    function createMockStoriesByStatus(stories) {
        const storiesByStatus = {
            Backlog: [],
            In_Progress: [],
            In_Review: [],
            Done: [],
            Blocked: []
        };

        if (stories && stories.length > 0) {
            stories.forEach(story => {
                const status = story.status || 'Backlog';
                if (!storiesByStatus[status]) {
                    storiesByStatus[status] = [];
                }
                storiesByStatus[status].push(story);
            });
        }

        return storiesByStatus;
    }

    // Helper to create drag event
    function createDragEvent(type, data) {
        const event = new Event(type, { bubbles: true, cancelable: true });
        event.dataTransfer = {
            effectAllowed: 'move',
            dropEffect: 'move',
            setData: jest.fn(),
            getData: jest.fn(() => data || '')
        };
        return event;
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
            expect(element.isUpdating).toBe(false);
            expect(element.draggedStoryId).toBe(null);
            expect(element.draggedStoryStatus).toBe(null);
            expect(element.statusColumns.length).toBe(5);
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

        it('initializes all status columns', () => {
            const element = createComponent();
            expect(element.statusColumns.length).toBe(5);
            expect(element.statusColumns[0].value).toBe('Backlog');
            expect(element.statusColumns[1].value).toBe('In_Progress');
            expect(element.statusColumns[2].value).toBe('In_Review');
            expect(element.statusColumns[3].value).toBe('Done');
            expect(element.statusColumns[4].value).toBe('Blocked');
        });
    });

    describe('Feature Filtering', () => {
        it('updates selectedFeatureId when feature filter changes', async () => {
            const mockFeatures = [createMockFeature('a0X000000000001AAA', 'Feature A')];
            const mockStoriesByStatus = createMockStoriesByStatus([]);

            getFeatures.mockResolvedValue(mockFeatures);
            getUserStoriesByStatus.mockResolvedValue(mockStoriesByStatus);

            const element = createComponent();
            await flushPromises();

            element.handleFeatureChange({
                detail: { value: 'a0X000000000001AAA' }
            });

            expect(element.selectedFeatureId).toBe('a0X000000000001AAA');
        });

        it('sets isLoading when feature filter changes', async () => {
            const mockFeatures = [createMockFeature('a0X000000000001AAA', 'Feature A')];
            const mockStoriesByStatus = createMockStoriesByStatus([]);

            getFeatures.mockResolvedValue(mockFeatures);
            getUserStoriesByStatus.mockResolvedValue(mockStoriesByStatus);

            const element = createComponent();
            await flushPromises();

            element.isLoading = false;
            element.handleFeatureChange({
                detail: { value: 'a0X000000000001AAA' }
            });

            expect(element.isLoading).toBe(true);
        });

        it('clears feature filter when handleClearFilters is called', async () => {
            const mockFeatures = [createMockFeature('a0X000000000001AAA', 'Feature A')];
            const mockStoriesByStatus = createMockStoriesByStatus([]);

            getFeatures.mockResolvedValue(mockFeatures);
            getUserStoriesByStatus.mockResolvedValue(mockStoriesByStatus);

            const element = createComponent();
            await flushPromises();

            element.selectedFeatureId = 'a0X000000000001AAA';
            element.handleClearFilters();

            expect(element.selectedFeatureId).toBe('');
        });

        it('sets isLoading when filters are cleared', async () => {
            const mockFeatures = [createMockFeature('a0X000000000001AAA', 'Feature A')];
            const mockStoriesByStatus = createMockStoriesByStatus([]);

            getFeatures.mockResolvedValue(mockFeatures);
            getUserStoriesByStatus.mockResolvedValue(mockStoriesByStatus);

            const element = createComponent();
            await flushPromises();

            element.isLoading = false;
            element.handleClearFilters();

            expect(element.isLoading).toBe(true);
        });

        it('hasFilters returns true when feature filter is active', async () => {
            const mockFeatures = [createMockFeature('a0X000000000001AAA', 'Feature A')];
            const mockStoriesByStatus = createMockStoriesByStatus([]);

            getFeatures.mockResolvedValue(mockFeatures);
            getUserStoriesByStatus.mockResolvedValue(mockStoriesByStatus);

            const element = createComponent();
            await flushPromises();

            element.selectedFeatureId = 'a0X000000000001AAA';
            expect(element.hasFilters).toBe(true);
        });

        it('hasFilters returns false when no filters are active', async () => {
            const mockFeatures = [];
            const mockStoriesByStatus = createMockStoriesByStatus([]);

            getFeatures.mockResolvedValue(mockFeatures);
            getUserStoriesByStatus.mockResolvedValue(mockStoriesByStatus);

            const element = createComponent();
            await flushPromises();

            expect(element.hasFilters).toBe(false);
        });
    });

    describe('Data Loading & Display', () => {
        it('loads and displays stories grouped by status', async () => {
            const mockFeatures = [];
            const mockStories = [
                createMockUserStory('a0Y000000000001AAA', 'Story 1', 'Backlog', 'High'),
                createMockUserStory('a0Y000000000002AAA', 'Story 2', 'In_Progress', 'Critical'),
                createMockUserStory('a0Y000000000003AAA', 'Story 3', 'Done', 'Low')
            ];
            const mockStoriesByStatus = createMockStoriesByStatus(mockStories);

            getFeatures.mockResolvedValue(mockFeatures);
            getUserStoriesByStatus.mockResolvedValue(mockStoriesByStatus);

            const element = createComponent();
            await flushPromises();

            expect(element.columnsWithStories.length).toBe(5);
            expect(element.columnsWithStories[0].stories.length).toBe(1); // Backlog
            expect(element.columnsWithStories[1].stories.length).toBe(1); // In_Progress
            expect(element.columnsWithStories[3].stories.length).toBe(1); // Done
        });

        it('displays empty columns correctly', async () => {
            const mockFeatures = [];
            const mockStoriesByStatus = createMockStoriesByStatus([]);

            getFeatures.mockResolvedValue(mockFeatures);
            getUserStoriesByStatus.mockResolvedValue(mockStoriesByStatus);

            const element = createComponent();
            await flushPromises();

            expect(element.columnsWithStories.length).toBe(5);
            element.columnsWithStories.forEach(column => {
                expect(column.count).toBe(0);
                expect(column.stories.length).toBe(0);
            });
        });

        it('formats status labels correctly', async () => {
            const mockFeatures = [];
            const mockStories = [
                createMockUserStory('a0Y000000000001AAA', 'Story 1', 'In_Progress'),
                createMockUserStory('a0Y000000000002AAA', 'Story 2', 'In_Review')
            ];
            const mockStoriesByStatus = createMockStoriesByStatus(mockStories);

            getFeatures.mockResolvedValue(mockFeatures);
            getUserStoriesByStatus.mockResolvedValue(mockStoriesByStatus);

            const element = createComponent();
            await flushPromises();

            const inProgressColumn = element.columnsWithStories.find(col => col.value === 'In_Progress');
            expect(inProgressColumn.stories[0].statusLabel).toBe('In Progress');

            const inReviewColumn = element.columnsWithStories.find(col => col.value === 'In_Review');
            expect(inReviewColumn.stories[0].statusLabel).toBe('In Review');
        });

        it('applies correct priority CSS classes', async () => {
            const mockFeatures = [];
            const mockStories = [
                createMockUserStory('a0Y000000000001AAA', 'Story 1', 'Backlog', 'Low'),
                createMockUserStory('a0Y000000000002AAA', 'Story 2', 'Backlog', 'High'),
                createMockUserStory('a0Y000000000003AAA', 'Story 3', 'Backlog', 'Critical')
            ];
            const mockStoriesByStatus = createMockStoriesByStatus(mockStories);

            getFeatures.mockResolvedValue(mockFeatures);
            getUserStoriesByStatus.mockResolvedValue(mockStoriesByStatus);

            const element = createComponent();
            await flushPromises();

            const backlogColumn = element.columnsWithStories.find(col => col.value === 'Backlog');
            expect(backlogColumn.stories[0].priorityClass).toContain('slds-badge_lightest');
            expect(backlogColumn.stories[1].priorityClass).toContain('slds-badge_warning');
            expect(backlogColumn.stories[2].priorityClass).toContain('slds-badge_error');
        });

        it('displays assignee information correctly', async () => {
            const mockFeatures = [];
            const mockStories = [
                createMockUserStory('a0Y000000000001AAA', 'Story 1', 'Backlog', 'Medium', null, '005000000000001AAA'),
                createMockUserStory('a0Y000000000002AAA', 'Story 2', 'Backlog', 'Medium', null, null)
            ];
            const mockStoriesByStatus = createMockStoriesByStatus(mockStories);

            getFeatures.mockResolvedValue(mockFeatures);
            getUserStoriesByStatus.mockResolvedValue(mockStoriesByStatus);

            const element = createComponent();
            await flushPromises();

            const backlogColumn = element.columnsWithStories.find(col => col.value === 'Backlog');
            expect(backlogColumn.stories[0].assigneeDisplay).toBe('Test User');
            expect(backlogColumn.stories[1].assigneeDisplay).toBe('Unassigned');
        });

        it('displays feature information correctly', async () => {
            const mockFeatures = [];
            const mockStories = [
                createMockUserStory('a0Y000000000001AAA', 'Story 1', 'Backlog', 'Medium', 'a0X000000000001AAA'),
                createMockUserStory('a0Y000000000002AAA', 'Story 2', 'Backlog', 'Medium', null)
            ];
            const mockStoriesByStatus = createMockStoriesByStatus(mockStories);

            getFeatures.mockResolvedValue(mockFeatures);
            getUserStoriesByStatus.mockResolvedValue(mockStoriesByStatus);

            const element = createComponent();
            await flushPromises();

            const backlogColumn = element.columnsWithStories.find(col => col.value === 'Backlog');
            expect(backlogColumn.stories[0].featureDisplay).toBe('Test Feature');
            expect(backlogColumn.stories[1].featureDisplay).toBe('No Feature');
        });
    });

    describe('Drag and Drop', () => {
        it('handles drag start correctly', async () => {
            const mockFeatures = [];
            const mockStories = [
                createMockUserStory('a0Y000000000001AAA', 'Story 1', 'Backlog', 'Medium')
            ];
            const mockStoriesByStatus = createMockStoriesByStatus(mockStories);

            getFeatures.mockResolvedValue(mockFeatures);
            getUserStoriesByStatus.mockResolvedValue(mockStoriesByStatus);

            const element = createComponent();
            await flushPromises();

            const mockTarget = {
                dataset: {
                    storyId: 'a0Y000000000001AAA',
                    storyStatus: 'Backlog'
                },
                classList: {
                    add: jest.fn(),
                    remove: jest.fn()
                }
            };

            const dragEvent = createDragEvent('dragstart');
            dragEvent.currentTarget = mockTarget;

            element.handleDragStart(dragEvent);

            expect(element.draggedStoryId).toBe('a0Y000000000001AAA');
            expect(element.draggedStoryStatus).toBe('Backlog');
            expect(dragEvent.dataTransfer.effectAllowed).toBe('move');
            expect(mockTarget.classList.add).toHaveBeenCalledWith('slds-is-dragging');
        });

        it('handles drag end correctly', async () => {
            const mockFeatures = [];
            const mockStories = [
                createMockUserStory('a0Y000000000001AAA', 'Story 1', 'Backlog', 'Medium')
            ];
            const mockStoriesByStatus = createMockStoriesByStatus(mockStories);

            getFeatures.mockResolvedValue(mockFeatures);
            getUserStoriesByStatus.mockResolvedValue(mockStoriesByStatus);

            const element = createComponent();
            await flushPromises();

            element.draggedStoryId = 'a0Y000000000001AAA';
            element.draggedStoryStatus = 'Backlog';

            const mockTarget = {
                classList: {
                    remove: jest.fn()
                }
            };

            const dragEvent = createDragEvent('dragend');
            dragEvent.currentTarget = mockTarget;

            element.handleDragEnd(dragEvent);

            expect(element.draggedStoryId).toBe(null);
            expect(element.draggedStoryStatus).toBe(null);
            expect(mockTarget.classList.remove).toHaveBeenCalledWith('slds-is-dragging');
        });

        it('handles drag over correctly', async () => {
            const mockFeatures = [];
            const mockStories = [
                createMockUserStory('a0Y000000000001AAA', 'Story 1', 'Backlog', 'Medium')
            ];
            const mockStoriesByStatus = createMockStoriesByStatus(mockStories);

            getFeatures.mockResolvedValue(mockFeatures);
            getUserStoriesByStatus.mockResolvedValue(mockStoriesByStatus);

            const element = createComponent();
            await flushPromises();

            element.draggedStoryId = 'a0Y000000000001AAA';

            const mockTarget = {
                dataset: {
                    status: 'In_Progress'
                },
                classList: {
                    add: jest.fn(),
                    remove: jest.fn()
                }
            };

            const dragEvent = createDragEvent('dragover');
            dragEvent.currentTarget = mockTarget;
            dragEvent.preventDefault = jest.fn();

            element.handleDragOver(dragEvent);

            expect(dragEvent.preventDefault).toHaveBeenCalled();
            expect(dragEvent.dataTransfer.dropEffect).toBe('move');
            expect(mockTarget.classList.add).toHaveBeenCalledWith('slds-is-drag-over');
        });

        it('handles drag leave correctly', async () => {
            const mockFeatures = [];
            const mockStories = [
                createMockUserStory('a0Y000000000001AAA', 'Story 1', 'Backlog', 'Medium')
            ];
            const mockStoriesByStatus = createMockStoriesByStatus(mockStories);

            getFeatures.mockResolvedValue(mockFeatures);
            getUserStoriesByStatus.mockResolvedValue(mockStoriesByStatus);

            const element = createComponent();
            await flushPromises();

            const mockTarget = {
                classList: {
                    remove: jest.fn()
                }
            };

            const dragEvent = createDragEvent('dragleave');
            dragEvent.currentTarget = mockTarget;

            element.handleDragLeave(dragEvent);

            expect(mockTarget.classList.remove).toHaveBeenCalledWith('slds-is-drag-over');
        });

        it('handles drop correctly and updates status', async () => {
            const mockFeatures = [];
            const mockStories = [
                createMockUserStory('a0Y000000000001AAA', 'Story 1', 'Backlog', 'Medium')
            ];
            const mockStoriesByStatus = createMockStoriesByStatus(mockStories);

            getFeatures.mockResolvedValue(mockFeatures);
            getUserStoriesByStatus.mockResolvedValue(mockStoriesByStatus);
            updateUserStoryStatus.mockResolvedValue(
                createMockUserStory('a0Y000000000001AAA', 'Story 1', 'In_Progress', 'Medium')
            );

            const element = createComponent();
            await flushPromises();

            element.draggedStoryId = 'a0Y000000000001AAA';
            element.draggedStoryStatus = 'Backlog';

            const mockTarget = {
                dataset: {
                    status: 'In_Progress'
                },
                classList: {
                    remove: jest.fn()
                }
            };

            const dropEvent = createDragEvent('drop');
            dropEvent.currentTarget = mockTarget;
            dropEvent.preventDefault = jest.fn();

            element.handleDrop(dropEvent);

            await flushPromises();

            expect(dropEvent.preventDefault).toHaveBeenCalled();
            expect(mockTarget.classList.remove).toHaveBeenCalledWith('slds-is-drag-over');
            expect(updateUserStoryStatus).toHaveBeenCalledWith({
                storyId: 'a0Y000000000001AAA',
                newStatus: 'In_Progress'
            });
        });

        it('ignores drop in same column', async () => {
            const mockFeatures = [];
            const mockStories = [
                createMockUserStory('a0Y000000000001AAA', 'Story 1', 'Backlog', 'Medium')
            ];
            const mockStoriesByStatus = createMockStoriesByStatus(mockStories);

            getFeatures.mockResolvedValue(mockFeatures);
            getUserStoriesByStatus.mockResolvedValue(mockStoriesByStatus);

            const element = createComponent();
            await flushPromises();

            element.draggedStoryId = 'a0Y000000000001AAA';
            element.draggedStoryStatus = 'Backlog';

            const mockTarget = {
                dataset: {
                    status: 'Backlog'
                },
                classList: {
                    remove: jest.fn()
                }
            };

            const dropEvent = createDragEvent('drop');
            dropEvent.currentTarget = mockTarget;
            dropEvent.preventDefault = jest.fn();

            element.handleDrop(dropEvent);

            expect(updateUserStoryStatus).not.toHaveBeenCalled();
        });

        it('ignores drop when no dragged story', async () => {
            const mockFeatures = [];
            const mockStories = [
                createMockUserStory('a0Y000000000001AAA', 'Story 1', 'Backlog', 'Medium')
            ];
            const mockStoriesByStatus = createMockStoriesByStatus(mockStories);

            getFeatures.mockResolvedValue(mockFeatures);
            getUserStoriesByStatus.mockResolvedValue(mockStoriesByStatus);

            const element = createComponent();
            await flushPromises();

            element.draggedStoryId = null;

            const mockTarget = {
                dataset: {
                    status: 'In_Progress'
                },
                classList: {
                    remove: jest.fn()
                }
            };

            const dropEvent = createDragEvent('drop');
            dropEvent.currentTarget = mockTarget;
            dropEvent.preventDefault = jest.fn();

            element.handleDrop(dropEvent);

            expect(updateUserStoryStatus).not.toHaveBeenCalled();
        });
    });

    describe('Status Updates', () => {
        it('updates story status successfully', async () => {
            const mockFeatures = [];
            const mockStories = [
                createMockUserStory('a0Y000000000001AAA', 'Story 1', 'Backlog', 'Medium')
            ];
            const mockStoriesByStatus = createMockStoriesByStatus(mockStories);

            getFeatures.mockResolvedValue(mockFeatures);
            getUserStoriesByStatus.mockResolvedValue(mockStoriesByStatus);
            updateUserStoryStatus.mockResolvedValue(
                createMockUserStory('a0Y000000000001AAA', 'Story 1', 'In_Progress', 'Medium')
            );

            const element = createComponent();
            await flushPromises();

            element.draggedStoryStatus = 'Backlog';
            element.storiesByStatus = {
                Backlog: [mockStories[0]],
                In_Progress: []
            };

            // Use setTimeout to simulate async refresh
            jest.useFakeTimers();
            element.updateStoryStatus('a0Y000000000001AAA', 'In_Progress');
            await flushPromises();
            jest.advanceTimersByTime(0);
            await flushPromises();
            jest.useRealTimers();

            expect(updateUserStoryStatus).toHaveBeenCalledWith({
                storyId: 'a0Y000000000001AAA',
                newStatus: 'In_Progress'
            });
        });

        it('prevents concurrent updates', async () => {
            const mockFeatures = [];
            const mockStories = [
                createMockUserStory('a0Y000000000001AAA', 'Story 1', 'Backlog', 'Medium')
            ];
            const mockStoriesByStatus = createMockStoriesByStatus(mockStories);

            getFeatures.mockResolvedValue(mockFeatures);
            getUserStoriesByStatus.mockResolvedValue(mockStoriesByStatus);

            const element = createComponent();
            await flushPromises();

            element.isUpdating = true;
            element.updateStoryStatus('a0Y000000000001AAA', 'In_Progress');

            expect(updateUserStoryStatus).not.toHaveBeenCalled();
        });

        it('shows success toast on successful update', async () => {
            const mockFeatures = [];
            const mockStories = [
                createMockUserStory('a0Y000000000001AAA', 'Story 1', 'Backlog', 'Medium')
            ];
            const mockStoriesByStatus = createMockStoriesByStatus(mockStories);
            const updatedStory = createMockUserStory('a0Y000000000001AAA', 'Story 1', 'In_Progress', 'Medium');

            getFeatures.mockResolvedValue(mockFeatures);
            getUserStoriesByStatus.mockResolvedValue(mockStoriesByStatus);
            updateUserStoryStatus.mockResolvedValue(updatedStory);

            const element = createComponent();
            await flushPromises();

            element.draggedStoryStatus = 'Backlog';
            element.storiesByStatus = {
                Backlog: [mockStories[0]],
                In_Progress: []
            };
            element.columnsWithStories = [
                { value: 'Backlog', stories: [mockStories[0]], count: 1 },
                { value: 'In_Progress', stories: [], count: 0 }
            ];

            jest.useFakeTimers();
            element.updateStoryStatus('a0Y000000000001AAA', 'In_Progress');
            await flushPromises();
            jest.advanceTimersByTime(0);
            await flushPromises();
            jest.useRealTimers();

            expect(mockShowToastEvent).toHaveBeenCalled();
        });

        it('shows error toast on failed update', async () => {
            const mockFeatures = [];
            const mockStories = [
                createMockUserStory('a0Y000000000001AAA', 'Story 1', 'Backlog', 'Medium')
            ];
            const mockStoriesByStatus = createMockStoriesByStatus(mockStories);
            const mockError = {
                body: {
                    message: 'Update failed'
                }
            };

            getFeatures.mockResolvedValue(mockFeatures);
            getUserStoriesByStatus.mockResolvedValue(mockStoriesByStatus);
            updateUserStoryStatus.mockRejectedValue(mockError);

            const element = createComponent();
            await flushPromises();

            element.draggedStoryStatus = 'Backlog';
            element.storiesByStatus = {
                Backlog: [mockStories[0]],
                In_Progress: []
            };
            element.columnsWithStories = [
                { value: 'Backlog', stories: [mockStories[0]], count: 1 },
                { value: 'In_Progress', stories: [], count: 0 }
            ];

            jest.useFakeTimers();
            element.updateStoryStatus('a0Y000000000001AAA', 'In_Progress');
            await flushPromises();
            jest.advanceTimersByTime(0);
            await flushPromises();
            jest.useRealTimers();

            expect(mockShowToastEvent).toHaveBeenCalled();
            expect(element.isUpdating).toBe(false);
        });

        it('refreshes data after successful update', async () => {
            const mockFeatures = [];
            const mockStories = [
                createMockUserStory('a0Y000000000001AAA', 'Story 1', 'Backlog', 'Medium')
            ];
            const mockStoriesByStatus = createMockStoriesByStatus(mockStories);
            const updatedStory = createMockUserStory('a0Y000000000001AAA', 'Story 1', 'In_Progress', 'Medium');

            getFeatures.mockResolvedValue(mockFeatures);
            getUserStoriesByStatus.mockResolvedValue(mockStoriesByStatus);
            updateUserStoryStatus.mockResolvedValue(updatedStory);

            const element = createComponent();
            await flushPromises();

            const initialCallCount = getUserStoriesByStatus.mock.calls.length;

            element.draggedStoryStatus = 'Backlog';
            element.storiesByStatus = {
                Backlog: [mockStories[0]],
                In_Progress: []
            };
            element.columnsWithStories = [
                { value: 'Backlog', stories: [mockStories[0]], count: 1 },
                { value: 'In_Progress', stories: [], count: 0 }
            ];

            jest.useFakeTimers();
            element.updateStoryStatus('a0Y000000000001AAA', 'In_Progress');
            await flushPromises();
            jest.advanceTimersByTime(0);
            await flushPromises();
            jest.useRealTimers();

            // Verify refresh was triggered (wire adapter should be called again)
            expect(getUserStoriesByStatus.mock.calls.length).toBeGreaterThan(initialCallCount);
        });
    });

    describe('Card Navigation', () => {
        it('navigates to record on card click', async () => {
            const mockFeatures = [];
            const mockStories = [
                createMockUserStory('a0Y000000000001AAA', 'Story 1', 'Backlog', 'Medium')
            ];
            const mockStoriesByStatus = createMockStoriesByStatus(mockStories);

            getFeatures.mockResolvedValue(mockFeatures);
            getUserStoriesByStatus.mockResolvedValue(mockStoriesByStatus);

            const element = createComponent();
            await flushPromises();

            const mockTarget = {
                dataset: {
                    storyId: 'a0Y000000000001AAA'
                }
            };

            const clickEvent = {
                currentTarget: mockTarget
            };

            element.handleCardClick(clickEvent);

            expect(mockNavigate).toHaveBeenCalledWith({
                type: 'standard__recordPage',
                attributes: {
                    recordId: 'a0Y000000000001AAA',
                    actionName: 'view'
                }
            });
        });

        it('navigates to record on Enter key press', async () => {
            const mockFeatures = [];
            const mockStories = [
                createMockUserStory('a0Y000000000001AAA', 'Story 1', 'Backlog', 'Medium')
            ];
            const mockStoriesByStatus = createMockStoriesByStatus(mockStories);

            getFeatures.mockResolvedValue(mockFeatures);
            getUserStoriesByStatus.mockResolvedValue(mockStoriesByStatus);

            const element = createComponent();
            await flushPromises();

            const mockTarget = {
                dataset: {
                    storyId: 'a0Y000000000001AAA'
                }
            };

            const keyEvent = {
                key: 'Enter',
                preventDefault: jest.fn(),
                currentTarget: mockTarget
            };

            element.handleCardKeyDown(keyEvent);

            expect(keyEvent.preventDefault).toHaveBeenCalled();
            expect(mockNavigate).toHaveBeenCalledWith({
                type: 'standard__recordPage',
                attributes: {
                    recordId: 'a0Y000000000001AAA',
                    actionName: 'view'
                }
            });
        });

        it('navigates to record on Space key press', async () => {
            const mockFeatures = [];
            const mockStories = [
                createMockUserStory('a0Y000000000001AAA', 'Story 1', 'Backlog', 'Medium')
            ];
            const mockStoriesByStatus = createMockStoriesByStatus(mockStories);

            getFeatures.mockResolvedValue(mockFeatures);
            getUserStoriesByStatus.mockResolvedValue(mockStoriesByStatus);

            const element = createComponent();
            await flushPromises();

            const mockTarget = {
                dataset: {
                    storyId: 'a0Y000000000001AAA'
                }
            };

            const keyEvent = {
                key: ' ',
                preventDefault: jest.fn(),
                currentTarget: mockTarget
            };

            element.handleCardKeyDown(keyEvent);

            expect(keyEvent.preventDefault).toHaveBeenCalled();
            expect(mockNavigate).toHaveBeenCalledWith({
                type: 'standard__recordPage',
                attributes: {
                    recordId: 'a0Y000000000001AAA',
                    actionName: 'view'
                }
            });
        });

        it('ignores other key presses', async () => {
            const mockFeatures = [];
            const mockStories = [
                createMockUserStory('a0Y000000000001AAA', 'Story 1', 'Backlog', 'Medium')
            ];
            const mockStoriesByStatus = createMockStoriesByStatus(mockStories);

            getFeatures.mockResolvedValue(mockFeatures);
            getUserStoriesByStatus.mockResolvedValue(mockStoriesByStatus);

            const element = createComponent();
            await flushPromises();

            const mockTarget = {
                dataset: {
                    storyId: 'a0Y000000000001AAA'
                }
            };

            const keyEvent = {
                key: 'Tab',
                preventDefault: jest.fn(),
                currentTarget: mockTarget
            };

            element.handleCardKeyDown(keyEvent);

            expect(keyEvent.preventDefault).not.toHaveBeenCalled();
            expect(mockNavigate).not.toHaveBeenCalled();
        });
    });

    describe('Error Handling', () => {
        it('displays error toast when getUserStoriesByStatus fails', async () => {
            const mockFeatures = [];
            const mockError = {
                body: {
                    message: 'Test error message'
                }
            };

            getFeatures.mockResolvedValue(mockFeatures);
            getUserStoriesByStatus.mockRejectedValue(mockError);

            const element = createComponent();
            await flushPromises();

            expect(mockShowToastEvent).toHaveBeenCalled();
            expect(element.error).toBeTruthy();
            expect(element.columnsWithStories.length).toBe(0);
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
            getUserStoriesByStatus.mockRejectedValue(mockError);

            const element = createComponent();
            await flushPromises();

            expect(mockShowToastEvent).toHaveBeenCalled();
        });

        it('clears stories on error', async () => {
            const mockFeatures = [];
            const mockError = {
                body: {
                    message: 'Test error'
                }
            };

            getFeatures.mockResolvedValue(mockFeatures);
            getUserStoriesByStatus.mockRejectedValue(mockError);

            const element = createComponent();
            await flushPromises();

            expect(element.storiesByStatus).toEqual({});
            expect(element.columnsWithStories.length).toBe(0);
        });
    });

    describe('Helper Methods', () => {
        it('getStatusLabel formats status values correctly', () => {
            const element = createComponent();

            expect(element.getStatusLabel('Backlog')).toBe('Backlog');
            expect(element.getStatusLabel('In_Progress')).toBe('In Progress');
            expect(element.getStatusLabel('In_Review')).toBe('In Review');
            expect(element.getStatusLabel('Done')).toBe('Done');
            expect(element.getStatusLabel('Blocked')).toBe('Blocked');
            expect(element.getStatusLabel('Unknown')).toBe('Unknown');
        });

        it('getPriorityClass returns correct CSS classes', () => {
            const element = createComponent();

            expect(element.getPriorityClass('Low')).toContain('slds-badge_lightest');
            expect(element.getPriorityClass('Medium')).toContain('slds-badge');
            expect(element.getPriorityClass('High')).toContain('slds-badge_warning');
            expect(element.getPriorityClass('Critical')).toContain('slds-badge_error');
            expect(element.getPriorityClass('Unknown')).toContain('slds-badge_lightest');
        });

        it('findStoryInStatus locates stories correctly', async () => {
            const mockFeatures = [];
            const mockStories = [
                createMockUserStory('a0Y000000000001AAA', 'Story 1', 'Backlog', 'Medium'),
                createMockUserStory('a0Y000000000002AAA', 'Story 2', 'Backlog', 'High')
            ];
            const mockStoriesByStatus = createMockStoriesByStatus(mockStories);

            getFeatures.mockResolvedValue(mockFeatures);
            getUserStoriesByStatus.mockResolvedValue(mockStoriesByStatus);

            const element = createComponent();
            await flushPromises();

            const story = element.findStoryInStatus('a0Y000000000001AAA', 'Backlog');
            expect(story).toBeTruthy();
            expect(story.id).toBe('a0Y000000000001AAA');

            const notFound = element.findStoryInStatus('a0Y000000000003AAA', 'Backlog');
            expect(notFound).toBeUndefined();
        });
    });

    describe('Wire Adapter Reactivity', () => {
        it('refetches data when selectedFeatureId changes', async () => {
            const mockFeatures = [createMockFeature('a0X000000000001AAA', 'Feature A')];
            const mockStoriesByStatus = createMockStoriesByStatus([]);

            getFeatures.mockResolvedValue(mockFeatures);
            getUserStoriesByStatus.mockResolvedValue(mockStoriesByStatus);

            const element = createComponent();
            await flushPromises();

            const initialCallCount = getUserStoriesByStatus.mock.calls.length;

            element.selectedFeatureId = 'a0X000000000001AAA';
            await flushPromises();

            expect(getUserStoriesByStatus.mock.calls.length).toBeGreaterThan(initialCallCount);
        });

        it('processes wiredStoriesByStatus data correctly', async () => {
            const mockFeatures = [];
            const mockStories = [
                createMockUserStory('a0Y000000000001AAA', 'Story 1', 'Backlog', 'Medium')
            ];
            const mockStoriesByStatus = createMockStoriesByStatus(mockStories);

            getFeatures.mockResolvedValue(mockFeatures);
            getUserStoriesByStatus.mockResolvedValue(mockStoriesByStatus);

            const element = createComponent();
            await flushPromises();

            expect(element.columnsWithStories.length).toBe(5);
            expect(element.storiesByStatus.Backlog.length).toBe(1);
        });

        it('processes wiredFeatures data correctly', async () => {
            const mockFeatures = [
                createMockFeature('a0X000000000001AAA', 'Feature A'),
                createMockFeature('a0X000000000002AAA', 'Feature B')
            ];

            getFeatures.mockResolvedValue(mockFeatures);
            getUserStoriesByStatus.mockResolvedValue(createMockStoriesByStatus([]));

            const element = createComponent();
            await flushPromises();

            expect(element.features.length).toBe(2);
            expect(element.featureOptions.length).toBe(3); // Includes "All Features"
        });

        it('sets isLoading to false after data loads', async () => {
            const mockFeatures = [];
            const mockStoriesByStatus = createMockStoriesByStatus([]);

            getFeatures.mockResolvedValue(mockFeatures);
            getUserStoriesByStatus.mockResolvedValue(mockStoriesByStatus);

            const element = createComponent();
            expect(element.isLoading).toBe(true);

            await flushPromises();

            expect(element.isLoading).toBe(false);
        });
    });

    describe('Accessibility', () => {
        it('sets proper ARIA labels on columns', async () => {
            const mockFeatures = [];
            const mockStoriesByStatus = createMockStoriesByStatus([]);

            getFeatures.mockResolvedValue(mockFeatures);
            getUserStoriesByStatus.mockResolvedValue(mockStoriesByStatus);

            const element = createComponent();
            await flushPromises();

            element.columnsWithStories.forEach(column => {
                expect(column.columnAriaLabel).toContain('column');
                expect(column.storiesAriaLabel).toContain('user stories');
            });
        });

        it('sets proper ARIA labels on story cards', async () => {
            const mockFeatures = [];
            const mockStories = [
                createMockUserStory('a0Y000000000001AAA', 'Story 1', 'Backlog', 'Medium')
            ];
            const mockStoriesByStatus = createMockStoriesByStatus(mockStories);

            getFeatures.mockResolvedValue(mockFeatures);
            getUserStoriesByStatus.mockResolvedValue(mockStoriesByStatus);

            const element = createComponent();
            await flushPromises();

            const backlogColumn = element.columnsWithStories.find(col => col.value === 'Backlog');
            expect(backlogColumn.stories[0].ariaLabel).toContain('User story');
            expect(backlogColumn.stories[0].ariaLabel).toContain('Story 1');
        });
    });
});

