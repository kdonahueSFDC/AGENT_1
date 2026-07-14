import { LightningElement, wire, track } from "lwc";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import getMyRequests from "@salesforce/apex/MyITRequestsController.getMyRequests";

const COLUMNS = [
  {
    label: "Request",
    fieldName: "recordLink",
    type: "url",
    typeAttributes: {
      label: { fieldName: "name" },
      target: "_self"
    },
    initialWidth: 130
  },
  {
    label: "Issue",
    fieldName: "issueDescription",
    type: "text",
    wrapText: true
  },
  {
    label: "Priority",
    fieldName: "priority",
    type: "text",
    initialWidth: 100
  },
  {
    label: "Status",
    fieldName: "status",
    type: "text",
    initialWidth: 120
  },
  {
    label: "Tier",
    fieldName: "assignedTier",
    type: "text",
    initialWidth: 100
  },
  {
    label: "SLA",
    fieldName: "slaStatus",
    type: "text",
    initialWidth: 110,
    cellAttributes: {
      class: { fieldName: "slaStatusClass" }
    }
  },
  {
    label: "Due By",
    fieldName: "dueBy",
    type: "date",
    typeAttributes: {
      year: "numeric",
      month: "short",
      day: "2-digit",
      hour: "2-digit",
      minute: "2-digit"
    }
  },
  {
    label: "Created",
    fieldName: "createdDate",
    type: "date",
    typeAttributes: {
      year: "numeric",
      month: "short",
      day: "2-digit"
    },
    initialWidth: 130
  }
];

const STATUS_OPTIONS = [
  { label: "All", value: "" },
  { label: "Open", value: "Open" },
  { label: "Resolved", value: "Resolved" }
];

export default class MyItRequests extends LightningElement {
  columns = COLUMNS;
  statusOptions = STATUS_OPTIONS;

  @track requests = [];
  emailInput = "";
  submittedEmail = "";
  statusFilter = "";
  isLoading = false;
  error;

  @wire(getMyRequests, {
    employeeEmail: "$submittedEmail",
    statusFilter: "$statusFilter"
  })
  wiredRequests({ error, data }) {
    this.isLoading = false;
    if (data) {
      this.requests = data;
      this.error = undefined;
    } else if (error) {
      this.error = error;
      this.requests = [];
      this.showErrorToast(
        "Error loading requests",
        error.body?.message || "Failed to load IT requests."
      );
    }
  }

  get hasSearched() {
    return this.submittedEmail !== "";
  }

  get hasResults() {
    return this.requests && this.requests.length > 0;
  }

  get resultsSummary() {
    if (!this.hasSearched) {
      return "";
    }
    const count = this.requests.length;
    if (count === 0) {
      return `No requests found for ${this.submittedEmail}.`;
    }
    return `Showing ${count} request${count === 1 ? "" : "s"} for ${this.submittedEmail}.`;
  }

  handleEmailChange(event) {
    this.emailInput = event.target.value;
  }

  handleStatusChange(event) {
    this.statusFilter = event.detail.value;
  }

  handleSearch() {
    const trimmed = (this.emailInput || "").trim();
    if (!trimmed) {
      this.showErrorToast(
        "Email required",
        "Enter your work email to look up your requests."
      );
      return;
    }
    this.isLoading = true;
    this.submittedEmail = trimmed;
  }

  handleKeyDown(event) {
    if (event.key === "Enter") {
      this.handleSearch();
    }
  }

  showErrorToast(title, message) {
    this.dispatchEvent(
      new ShowToastEvent({
        title,
        message,
        variant: "error"
      })
    );
  }
}
