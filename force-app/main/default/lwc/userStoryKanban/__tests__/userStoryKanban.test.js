import { createElement } from "lwc";
import UserStoryKanban from "c/userStoryKanban";
import getFeatures from "@salesforce/apex/UserStoryController.getFeatures";
import getUserStoriesByStatus from "@salesforce/apex/UserStoryController.getUserStoriesByStatus";
import updateUserStoryStatus from "@salesforce/apex/UserStoryController.updateUserStoryStatus";

// Mock realistic data
const mockGetFeatures = require("./data/getFeatures.json");
const mockGetUserStoriesByStatus = require("./data/getUserStoriesByStatus.json");

// Mock the Apex wire adapters
jest.mock(
  "@salesforce/apex/UserStoryController.getFeatures",
  () => {
    const { createApexTestWireAdapter } = require("@salesforce/sfdx-lwc-jest");
    return {
      default: createApexTestWireAdapter(jest.fn())
    };
  },
  { virtual: true }
);

jest.mock(
  "@salesforce/apex/UserStoryController.getUserStoriesByStatus",
  () => {
    const { createApexTestWireAdapter } = require("@salesforce/sfdx-lwc-jest");
    return {
      default: createApexTestWireAdapter(jest.fn())
    };
  },
  { virtual: true }
);

// Mock imperative Apex
jest.mock(
  "@salesforce/apex/UserStoryController.updateUserStoryStatus",
  () => {
    return { default: jest.fn() };
  },
  { virtual: true }
);

// Mock refreshApex
jest.mock(
  "@salesforce/apex",
  () => ({
    refreshApex: jest.fn(() => Promise.resolve())
  }),
  { virtual: true }
);

// Mock NavigationMixin
jest.mock(
  "lightning/navigation",
  () => {
    const Navigate = jest.fn();
    return {
      NavigationMixin: (Base) => {
        return class extends Base {
          [Navigate]() {
            // Mock implementation
          }
        };
      },
      Navigate
    };
  },
  { virtual: true }
);

// Helper to flush promises
async function flushPromises() {
  await Promise.resolve();
  await Promise.resolve();
  await Promise.resolve();
}

describe("c-user-story-kanban", () => {
  afterEach(() => {
    while (document.body.firstChild) {
      document.body.removeChild(document.body.firstChild);
    }
    jest.clearAllMocks();
  });

  it("renders 5 status columns after wire emits data", async () => {
    const element = createElement("c-user-story-kanban", {
      is: UserStoryKanban
    });
    document.body.appendChild(element);

    getFeatures.emit(mockGetFeatures);
    getUserStoriesByStatus.emit(mockGetUserStoriesByStatus);
    await flushPromises();

    const columns = element.shadowRoot.querySelectorAll(".kanban-column");
    expect(columns.length).toBe(5);

    const columnHeaders = element.shadowRoot.querySelectorAll(
      ".slds-card__header-title span"
    );
    const expectedHeaders = [
      "Backlog",
      "In Progress",
      "In Review",
      "Done",
      "Blocked"
    ];
    columnHeaders.forEach((header, index) => {
      expect(header.textContent).toBe(expectedHeaders[index]);
    });
  });

  it("renders enhanced stories with display fields", async () => {
    const element = createElement("c-user-story-kanban", {
      is: UserStoryKanban
    });
    document.body.appendChild(element);

    getFeatures.emit(mockGetFeatures);
    getUserStoriesByStatus.emit(mockGetUserStoriesByStatus);
    await flushPromises();

    const storyCard = element.shadowRoot.querySelector(".kanban-card");
    expect(storyCard).not.toBeNull();
  });

  it("updateStoryStatus is called with correct args when a drop happens", async () => {
    const element = createElement("c-user-story-kanban", {
      is: UserStoryKanban
    });
    document.body.appendChild(element);

    getFeatures.emit(mockGetFeatures);
    getUserStoriesByStatus.emit(mockGetUserStoriesByStatus);
    await flushPromises();

    const mockUpdatedStory = {
      id: "a031234567890AAAA",
      name: "US-101",
      status: "Done"
    };
    updateUserStoryStatus.mockResolvedValue(mockUpdatedStory);

    const storyCard = element.shadowRoot.querySelector(
      '[data-story-id="a031234567890AAAA"]'
    );
    expect(storyCard).not.toBeNull();

    const dragStartEvent = new CustomEvent("dragstart", { bubbles: true });
    Object.defineProperty(dragStartEvent, "dataTransfer", {
      value: {
        effectAllowed: "",
        setData: jest.fn()
      },
      writable: false
    });
    Object.defineProperty(dragStartEvent, "currentTarget", {
      value: storyCard,
      writable: false
    });
    storyCard.dispatchEvent(dragStartEvent);
    await flushPromises();

    const dropColumn = element.shadowRoot.querySelector('[data-status="Done"]');
    expect(dropColumn).not.toBeNull();

    const dropEvent = new CustomEvent("drop", {
      bubbles: true,
      cancelable: true
    });
    Object.defineProperty(dropEvent, "preventDefault", {
      value: jest.fn()
    });
    Object.defineProperty(dropEvent, "currentTarget", {
      value: dropColumn
    });

    dropColumn.dispatchEvent(dropEvent);
    await flushPromises();

    expect(updateUserStoryStatus).toHaveBeenCalledWith({
      storyId: "a031234567890AAAA",
      newStatus: "Done"
    });
  });

  it("emits error toast on Apex failure", async () => {
    const element = createElement("c-user-story-kanban", {
      is: UserStoryKanban
    });
    document.body.appendChild(element);

    getFeatures.emit(mockGetFeatures);
    getUserStoriesByStatus.emit(mockGetUserStoriesByStatus);
    await flushPromises();

    const mockError = {
      body: { message: "Failed to update story status" }
    };
    updateUserStoryStatus.mockRejectedValue(mockError);

    let toastEvent = null;
    element.addEventListener("lightning__showtoast", (event) => {
      toastEvent = event;
    });

    const storyCard = element.shadowRoot.querySelector(
      '[data-story-id="a031234567890AAAA"]'
    );
    expect(storyCard).not.toBeNull();

    const dragStartEvent = new CustomEvent("dragstart", { bubbles: true });
    Object.defineProperty(dragStartEvent, "dataTransfer", {
      value: {
        effectAllowed: "",
        setData: jest.fn()
      },
      writable: false
    });
    Object.defineProperty(dragStartEvent, "currentTarget", {
      value: storyCard,
      writable: false
    });
    storyCard.dispatchEvent(dragStartEvent);
    await flushPromises();

    const dropColumn = element.shadowRoot.querySelector('[data-status="Done"]');
    const dropEvent = new CustomEvent("drop", {
      bubbles: true,
      cancelable: true
    });
    Object.defineProperty(dropEvent, "preventDefault", {
      value: jest.fn()
    });
    Object.defineProperty(dropEvent, "currentTarget", {
      value: dropColumn
    });

    dropColumn.dispatchEvent(dropEvent);
    await flushPromises();

    expect(toastEvent).not.toBeNull();
    expect(toastEvent.detail.title).toBe("Update Failed");
    expect(toastEvent.detail.variant).toBe("error");
  });

  it("emits error toast when wire emits error", async () => {
    const element = createElement("c-user-story-kanban", {
      is: UserStoryKanban
    });
    document.body.appendChild(element);

    const mockError = {
      body: { message: "Failed to load user stories" }
    };

    let toastEvent = null;
    element.addEventListener("lightning__showtoast", (event) => {
      toastEvent = event;
    });

    getUserStoriesByStatus.error(mockError);
    await flushPromises();

    expect(toastEvent).not.toBeNull();
    expect(toastEvent.detail.title).toBe("Error Loading User Stories");
    expect(toastEvent.detail.variant).toBe("error");
  });

  it("keyboard accessible move menu calls updateUserStoryStatus", async () => {
    const element = createElement("c-user-story-kanban", {
      is: UserStoryKanban
    });
    document.body.appendChild(element);

    getFeatures.emit(mockGetFeatures);
    getUserStoriesByStatus.emit(mockGetUserStoriesByStatus);
    await flushPromises();

    const mockUpdatedStory = {
      id: "a031234567890AAAA",
      name: "US-101",
      status: "In_Progress"
    };
    updateUserStoryStatus.mockResolvedValue(mockUpdatedStory);

    const buttonMenu = element.shadowRoot.querySelector(
      'lightning-button-menu[data-story-id="a031234567890AAAA"]'
    );
    expect(buttonMenu).not.toBeNull();

    const selectEvent = new CustomEvent("select", {
      detail: { value: "In_Progress" },
      bubbles: true
    });
    Object.defineProperty(selectEvent, "currentTarget", {
      value: buttonMenu,
      writable: false
    });

    buttonMenu.dispatchEvent(selectEvent);
    await flushPromises();

    expect(updateUserStoryStatus).toHaveBeenCalledWith({
      storyId: "a031234567890AAAA",
      newStatus: "In_Progress"
    });
  });
});
