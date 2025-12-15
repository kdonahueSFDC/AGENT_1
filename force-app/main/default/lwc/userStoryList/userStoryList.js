import { LightningElement, wire, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getUserStories from '@salesforce/apex/UserStoryController.getUserStories';
import getFeatures from '@salesforce/apex/UserStoryController.getFeatures';

const COLUMNS = [
    {
        label: 'User Story',
        fieldName: 'recordLink',
        type: 'url',
        typeAttributes: {
            label: { fieldName: 'name' },
            target: '_self'
        },
        sortable: true,
        initialWidth: 200
    },
    {
        label: 'Feature',
        fieldName: 'featureName',
        type: 'text',
        sortable: true
    },
    {
        label: 'Status',
        fieldName: 'statusLabel',
        type: 'text',
        sortable: true,
        cellAttributes: {
            class: { fieldName: 'statusClass' }
        }
    },
    {
        label: 'Priority',
        fieldName: 'priority',
        type: 'text',
        sortable: true,
        cellAttributes: {
            class: { fieldName: 'priorityClass' }
        }
    },
    {
        label: 'Assignee',
        fieldName: 'assigneeName',
        type: 'text',
        sortable: true
    },
    {
        label: 'Created Date',
        fieldName: 'createdDate',
        type: 'date',
        typeAttributes: {
            year: 'numeric',
            month: 'short',
            day: '2-digit'
        },
        sortable: true
    }
];

const STATUS_OPTIONS = [
    { label: 'All Statuses', value: '' },
    { label: 'Backlog', value: 'Backlog' },
    { label: 'In Progress', value: 'In_Progress' },
    { label: 'In Review', value: 'In_Review' },
    { label: 'Done', value: 'Done' },
    { label: 'Blocked', value: 'Blocked' }
];

const PRIORITY_OPTIONS = [
    { label: 'All Priorities', value: '' },
    { label: 'Low', value: 'Low' },
    { label: 'Medium', value: 'Medium' },
    { label: 'High', value: 'High' },
    { label: 'Critical', value: 'Critical' }
];

const PAGE_SIZE = 25;
const DEFAULT_SORT_BY = 'Name';
const DEFAULT_SORT_DIRECTION = 'asc';

export default class UserStoryList extends LightningElement {
    columns = COLUMNS;
    statusOptions = STATUS_OPTIONS;
    priorityOptions = PRIORITY_OPTIONS;
    
    @track userStories = [];
    @track features = [];
    @track featureOptions = [];
    
    // Filter values
    selectedFeatureId = '';
    selectedStatus = '';
    selectedPriority = '';
    assigneeId = '';
    
    // Pagination
    currentPage = 1;
    totalRecords = 0;
    totalPages = 0;
    pageSize = PAGE_SIZE;
    
    // Sorting
    sortBy = DEFAULT_SORT_BY;
    sortDirection = DEFAULT_SORT_DIRECTION;
    
    isLoading = false;
    error;

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

    @wire(getUserStories, {
        featureId: '$selectedFeatureId',
        status: '$selectedStatus',
        priority: '$selectedPriority',
        assigneeId: '$assigneeId',
        pageNumber: '$currentPage',
        pageSize: '$pageSize',
        sortBy: '$sortBy',
        sortDirection: '$sortDirection'
    })
    wiredUserStories({ error, data }) {
        this.isLoading = false;
        if (data) {
            // Enhance data with CSS classes for status and priority, and record link
            this.userStories = (data.records || []).map(story => ({
                ...story,
                recordLink: '/' + story.id,
                statusClass: this.getStatusClass(story.status),
                priorityClass: this.getPriorityClass(story.priority),
                statusLabel: this.getStatusLabel(story.status)
            }));
            this.totalRecords = data.totalRecords || 0;
            this.totalPages = data.totalPages || 0;
            this.error = undefined;
        } else if (error) {
            this.error = error;
            this.userStories = [];
            this.showErrorToast('Error Loading User Stories', error.body?.message || 'Failed to load user stories.');
        }
    }

    connectedCallback() {
        this.isLoading = true;
    }

    get hasPreviousPage() {
        return this.currentPage > 1;
    }

    get hasNextPage() {
        return this.currentPage < this.totalPages;
    }

    get isPreviousDisabled() {
        return !this.hasPreviousPage || this.isLoading;
    }

    get isNextDisabled() {
        return !this.hasNextPage || this.isLoading;
    }

    get pageInfo() {
        if (this.totalRecords === 0) {
            return 'No user stories found';
        }
        const start = (this.currentPage - 1) * this.pageSize + 1;
        const end = Math.min(this.currentPage * this.pageSize, this.totalRecords);
        return `Showing ${start}-${end} of ${this.totalRecords} user stories`;
    }

    get hasFilters() {
        return this.selectedFeatureId || this.selectedStatus || this.selectedPriority || this.assigneeId;
    }

    handleFeatureChange(event) {
        this.selectedFeatureId = event.detail.value;
        this.resetToFirstPage();
    }

    handleStatusChange(event) {
        this.selectedStatus = event.detail.value;
        this.resetToFirstPage();
    }

    handlePriorityChange(event) {
        this.selectedPriority = event.detail.value;
        this.resetToFirstPage();
    }

    handleClearFilters() {
        this.selectedFeatureId = '';
        this.selectedStatus = '';
        this.selectedPriority = '';
        this.assigneeId = '';
        this.resetToFirstPage();
    }

    handlePrevious() {
        if (this.hasPreviousPage) {
            this.isLoading = true;
            this.currentPage = this.currentPage - 1;
        }
    }

    handleNext() {
        if (this.hasNextPage) {
            this.isLoading = true;
            this.currentPage = this.currentPage + 1;
        }
    }

    handleSort(event) {
        const { fieldName, sortDirection } = event.detail;
        
        // Map field names from datatable to Apex field names
        const fieldMapping = {
            'name': 'Name',
            'featureName': 'Feature__r.Name',
            'status': 'Status__c',
            'priority': 'Priority__c',
            'assigneeName': 'Assignee__r.Name',
            'createdDate': 'CreatedDate'
        };
        
        this.sortBy = fieldMapping[fieldName] || DEFAULT_SORT_BY;
        this.sortDirection = sortDirection || DEFAULT_SORT_DIRECTION;
        this.isLoading = true;
        // Reset to first page when sorting changes
        this.currentPage = 1;
    }


    resetToFirstPage() {
        this.isLoading = true;
        this.currentPage = 1;
    }

    getStatusClass(status) {
        const statusClassMap = {
            'Backlog': 'slds-text-color_default',
            'In_Progress': 'slds-text-color_success',
            'In_Review': 'slds-text-color_warning',
            'Done': 'slds-text-color_success',
            'Blocked': 'slds-text-color_error'
        };
        return statusClassMap[status] || 'slds-text-color_default';
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
            'Low': 'slds-text-color_default',
            'Medium': 'slds-text-color_default',
            'High': 'slds-text-color_warning',
            'Critical': 'slds-text-color_error'
        };
        return priorityClassMap[priority] || 'slds-text-color_default';
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

