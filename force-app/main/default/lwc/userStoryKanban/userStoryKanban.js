import { LightningElement, wire, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { NavigationMixin } from 'lightning/navigation';
import getUserStoriesByStatus from '@salesforce/apex/UserStoryController.getUserStoriesByStatus';
import updateUserStoryStatus from '@salesforce/apex/UserStoryController.updateUserStoryStatus';
import getFeatures from '@salesforce/apex/UserStoryController.getFeatures';

const STATUS_COLUMNS = [
    { value: 'Backlog', label: 'Backlog', icon: 'standard:backlog' },
    { value: 'In_Progress', label: 'In Progress', icon: 'standard:task' },
    { value: 'In_Review', label: 'In Review', icon: 'standard:approval' },
    { value: 'Done', label: 'Done', icon: 'standard:success' },
    { value: 'Blocked', label: 'Blocked', icon: 'standard:block_visitor' }
];

export default class UserStoryKanban extends NavigationMixin(LightningElement) {
    statusColumns = STATUS_COLUMNS;
    
    @track storiesByStatus = {};
    @track features = [];
    @track featureOptions = [];
    
    selectedFeatureId = '';
    isLoading = false;
    isUpdating = false;
    error;
    draggedStoryId = null;
    draggedStoryStatus = null;

    @wire(getFeatures)
    wiredFeatures({ error, data }) {
        if (data) {
            this.features = data;
            this.featureOptions = [
                { label: 'All Features', value: '' },
                ...data.map(feature => ({
                    label: feature.name,
                    value: feature.id
                }))
            ];
            this.error = undefined;
        } else if (error) {
            this.error = error;
            this.showErrorToast('Error Loading Features', error.body?.message || 'Failed to load features.');
        }
    }

    @track columnsWithStories = [];

    @wire(getUserStoriesByStatus, { featureId: '$selectedFeatureId' })
    wiredStoriesByStatus({ error, data }) {
        this.isLoading = false;
        if (data) {
            // Initialize storiesByStatus with all status columns
            this.storiesByStatus = {};
            // Create columns with stories for template
            this.columnsWithStories = STATUS_COLUMNS.map(column => {
                const stories = (data[column.value] || []).map(story => ({
                    ...story,
                    statusLabel: this.getStatusLabel(story.status),
                    priorityLabel: story.priority || 'Not Set',
                    priorityClass: this.getPriorityClass(story.priority),
                    assigneeDisplay: story.assigneeName || 'Unassigned',
                    featureDisplay: story.featureName || 'No Feature'
                }));
                this.storiesByStatus[column.value] = stories;
                return {
                    ...column,
                    stories: stories,
                    count: stories.length
                };
            });
            this.error = undefined;
        } else if (error) {
            this.error = error;
            this.storiesByStatus = {};
            this.columnsWithStories = [];
            this.showErrorToast('Error Loading User Stories', error.body?.message || 'Failed to load user stories.');
        }
    }

    connectedCallback() {
        this.isLoading = true;
    }

    get hasFilters() {
        return this.selectedFeatureId !== '';
    }

    handleFeatureChange(event) {
        this.selectedFeatureId = event.detail.value;
        this.isLoading = true;
    }

    handleClearFilters() {
        this.selectedFeatureId = '';
        this.isLoading = true;
    }

    handleDragStart(event) {
        const storyId = event.currentTarget.dataset.storyId;
        const storyStatus = event.currentTarget.dataset.storyStatus;
        
        if (storyId && storyStatus) {
            this.draggedStoryId = storyId;
            this.draggedStoryStatus = storyStatus;
            event.dataTransfer.effectAllowed = 'move';
            event.dataTransfer.setData('text/plain', storyId);
            
            // Add visual feedback
            event.currentTarget.classList.add('slds-is-dragging');
        }
    }

    handleDragEnd(event) {
        event.currentTarget.classList.remove('slds-is-dragging');
        this.draggedStoryId = null;
        this.draggedStoryStatus = null;
    }

    handleDragOver(event) {
        event.preventDefault();
        event.dataTransfer.dropEffect = 'move';
        
        const column = event.currentTarget;
        if (this.draggedStoryId && column.dataset.status) {
            column.classList.add('slds-is-drag-over');
        }
    }

    handleDragLeave(event) {
        const column = event.currentTarget;
        column.classList.remove('slds-is-drag-over');
    }

    handleDrop(event) {
        event.preventDefault();
        const column = event.currentTarget;
        column.classList.remove('slds-is-drag-over');
        
        const newStatus = column.dataset.status;
        
        if (!this.draggedStoryId || !newStatus) {
            return;
        }
        
        // Don't update if dropped in the same column
        if (this.draggedStoryStatus === newStatus) {
            return;
        }
        
        // Update the story status
        this.updateStoryStatus(this.draggedStoryId, newStatus);
    }

    handleCardClick(event) {
        const storyId = event.currentTarget.dataset.storyId;
        if (storyId) {
            this.navigateToRecord(storyId);
        }
    }

    handleCardKeyDown(event) {
        // Allow Enter or Space to navigate
        if (event.key === 'Enter' || event.key === ' ') {
            event.preventDefault();
            const storyId = event.currentTarget.dataset.storyId;
            if (storyId) {
                this.navigateToRecord(storyId);
            }
        }
    }

    updateStoryStatus(storyId, newStatus) {
        if (this.isUpdating) {
            return;
        }
        
        this.isUpdating = true;
        
        // Optimistically update the UI
        const oldStatus = this.draggedStoryStatus;
        const story = this.findStoryInStatus(storyId, oldStatus);
        
        if (story) {
            // Remove from old status
            this.storiesByStatus[oldStatus] = this.storiesByStatus[oldStatus].filter(
                s => s.id !== storyId
            );
            
            // Add to new status with updated status
            const updatedStory = {
                ...story,
                status: newStatus,
                statusLabel: this.getStatusLabel(newStatus)
            };
            this.storiesByStatus[newStatus] = [...(this.storiesByStatus[newStatus] || []), updatedStory];
            
            // Update columnsWithStories array for template reactivity
            this.columnsWithStories = this.columnsWithStories.map(column => {
                if (column.value === oldStatus) {
                    return {
                        ...column,
                        stories: this.storiesByStatus[oldStatus],
                        count: this.storiesByStatus[oldStatus].length
                    };
                } else if (column.value === newStatus) {
                    return {
                        ...column,
                        stories: this.storiesByStatus[newStatus],
                        count: this.storiesByStatus[newStatus].length
                    };
                }
                return column;
            });
        }
        
        // Call Apex to persist the change
        updateUserStoryStatus({ storyId: storyId, newStatus: newStatus })
            .then((updatedStory) => {
                this.isUpdating = false;
                this.showSuccessToast('Status Updated', `User story "${updatedStory.name}" moved to ${this.getStatusLabel(newStatus)}.`);
                
                // Refresh data to ensure consistency
                this.refreshData();
            })
            .catch((error) => {
                this.isUpdating = false;
                this.showErrorToast('Update Failed', error.body?.message || 'Failed to update user story status.');
                
                // Revert optimistic update
                this.refreshData();
            });
    }

    findStoryInStatus(storyId, status) {
        const stories = this.storiesByStatus[status] || [];
        return stories.find(s => s.id === storyId);
    }

    refreshData() {
        // Trigger wire refresh by updating reactive property
        const currentFeatureId = this.selectedFeatureId;
        this.selectedFeatureId = '';
        // Use setTimeout to ensure the wire picks up the change
        setTimeout(() => {
            this.selectedFeatureId = currentFeatureId;
        }, 0);
    }

    navigateToRecord(recordId) {
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: recordId,
                actionName: 'view'
            }
        });
    }

    getStatusLabel(status) {
        const statusLabelMap = {
            'Backlog': 'Backlog',
            'In_Progress': 'In Progress',
            'In_Review': 'In Review',
            'Done': 'Done',
            'Blocked': 'Blocked'
        };
        return statusLabelMap[status] || status;
    }

    getPriorityClass(priority) {
        const priorityClassMap = {
            'Low': 'slds-badge slds-badge_lightest',
            'Medium': 'slds-badge',
            'High': 'slds-badge slds-badge_warning',
            'Critical': 'slds-badge slds-badge_error'
        };
        return priorityClassMap[priority] || 'slds-badge slds-badge_lightest';
    }


    showSuccessToast(title, message) {
        const evt = new ShowToastEvent({
            title: title,
            message: message,
            variant: 'success',
            mode: 'dismissable'
        });
        this.dispatchEvent(evt);
    }

    showErrorToast(title, message) {
        const evt = new ShowToastEvent({
            title: title,
            message: message,
            variant: 'error',
            mode: 'sticky'
        });
        this.dispatchEvent(evt);
    }
}

