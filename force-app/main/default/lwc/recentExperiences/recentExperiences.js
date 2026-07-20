import { LightningElement, wire } from "lwc";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import getRecentExperiences from "@salesforce/apex/ExperienceController.getRecentExperiences";

const COLUMNS = [
  {
    label: "Experience Name",
    fieldName: "Name",
    type: "text",
    sortable: true
  },
  {
    label: "Type",
    fieldName: "Type__c",
    type: "text",
    sortable: true
  },
  {
    label: "Location",
    fieldName: "Location__c",
    type: "text",
    sortable: true
  },
  {
    label: "Price",
    fieldName: "Price__c",
    type: "currency",
    typeAttributes: {
      currencyCode: "USD",
      minimumFractionDigits: 2
    },
    sortable: true
  },
  {
    label: "Capacity",
    fieldName: "Capacity__c",
    type: "number",
    sortable: true
  },
  {
    label: "Rating",
    fieldName: "Rating__c",
    type: "number",
    typeAttributes: {
      minimumFractionDigits: 1,
      maximumFractionDigits: 1
    },
    sortable: true
  },
  {
    label: "Created Date",
    fieldName: "CreatedDate",
    type: "date",
    typeAttributes: {
      year: "numeric",
      month: "short",
      day: "2-digit"
    },
    sortable: true
  }
];

const PAGE_SIZE = 5;

export default class RecentExperiences extends LightningElement {
  columns = COLUMNS;
  experiences = [];
  currentPage = 1;
  totalRecords = 0;
  totalPages = 0;
  pageSize = PAGE_SIZE;
  isLoading = false;
  error;
  sortBy = "Name";
  sortDirection = "asc";

  @wire(getRecentExperiences, {
    pageNumber: "$currentPage",
    pageSize: "$pageSize"
  })
  wiredExperiences({ error, data }) {
    this.isLoading = false;
    if (data) {
      this.experiences = data.records || [];
      this.totalRecords = data.totalRecords || 0;
      this.totalPages = data.totalPages || 0;
      this.error = undefined;
    } else if (error) {
      this.error = error;
      this.experiences = [];
      this.showErrorToast();
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
    return !this.hasPreviousPage;
  }

  get isNextDisabled() {
    return !this.hasNextPage;
  }

  get pageInfo() {
    if (this.totalRecords === 0) {
      return "No records found";
    }
    const start = (this.currentPage - 1) * this.pageSize + 1;
    const end = Math.min(this.currentPage * this.pageSize, this.totalRecords);
    return `Showing ${start}-${end} of ${this.totalRecords} experiences`;
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
    this.sortBy = fieldName;
    this.sortDirection = sortDirection;

    // Sort a copy of experiences array
    const sorted = [...this.experiences];
    const isReverse = sortDirection === "desc";

    sorted.sort((a, b) => {
      let valA = a[fieldName];
      let valB = b[fieldName];

      // Handle nulls - sort them last
      if (valA == null && valB == null) return 0;
      if (valA == null) return 1;
      if (valB == null) return -1;

      // Type-aware comparison
      if (typeof valA === "string" && typeof valB === "string") {
        valA = valA.toLowerCase();
        valB = valB.toLowerCase();
      }

      if (valA < valB) return isReverse ? 1 : -1;
      if (valA > valB) return isReverse ? -1 : 1;
      return 0;
    });

    this.experiences = sorted;
  }

  showErrorToast() {
    const evt = new ShowToastEvent({
      title: "Error Loading Experiences",
      message:
        this.error?.body?.message ||
        "An error occurred while loading experiences.",
      variant: "error",
      mode: "sticky"
    });
    this.dispatchEvent(evt);
  }
}
