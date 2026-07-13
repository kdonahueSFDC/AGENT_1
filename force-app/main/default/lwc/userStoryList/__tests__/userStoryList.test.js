import { createElement } from "lwc";
import UserStoryList from "c/userStoryList";
import getFeatures from "@salesforce/apex/UserStoryController.getFeatures";
import getUserStories from "@salesforce/apex/UserStoryController.getUserStories";

// Mock realistic data
const mockGetFeatures = require("./data/getFeatures.json");
const mockGetUserStories = require("./data/getUserStories.json");
const mockEmptyUserStories = require("./data/emptyUserStories.json");

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
  "@salesforce/apex/UserStoryController.getUserStories",
  () => {
    const { createApexTestWireAdapter } = require("@salesforce/sfdx-lwc-jest");
    return {
      default: createApexTestWireAdapter(jest.fn())
    };
  },
  { virtual: true }
);

// Helper to flush promises
function flushPromises() {
  return Promise.resolve();
}

describe("c-user-story-list", () => {
  afterEach(() => {
    while (document.body.firstChild) {
      document.body.removeChild(document.body.firstChild);
    }
    jest.clearAllMocks();
  });

  it("renders datatable when wire emits records", async () => {
    const element = createElement("c-user-story-list", {
      is: UserStoryList
    });
    document.body.appendChild(element);

    getFeatures.emit(mockGetFeatures);
    getUserStories.emit(mockGetUserStories);
    await flushPromises();

    const datatable = element.shadowRoot.querySelector("lightning-datatable");
    expect(datatable).not.toBeNull();
    expect(datatable.data.length).toBe(2);
    expect(datatable.data[0].name).toBe("US-101");
  });

  it("shows empty state when zero records", async () => {
    const element = createElement("c-user-story-list", {
      is: UserStoryList
    });
    document.body.appendChild(element);

    getFeatures.emit(mockGetFeatures);
    getUserStories.emit(mockEmptyUserStories);
    await flushPromises();

    const emptyMessage = element.shadowRoot.querySelector("p");
    expect(emptyMessage).not.toBeNull();
    expect(emptyMessage.textContent).toBe("No user stories found.");

    const datatable = element.shadowRoot.querySelector("lightning-datatable");
    expect(datatable).toBeNull();
  });

  it("renders enhanced user stories with CSS classes", async () => {
    const element = createElement("c-user-story-list", {
      is: UserStoryList
    });
    document.body.appendChild(element);

    getFeatures.emit(mockGetFeatures);
    getUserStories.emit(mockGetUserStories);
    await flushPromises();

    const datatable = element.shadowRoot.querySelector("lightning-datatable");
    expect(datatable.data[0].statusClass).toBeDefined();
    expect(datatable.data[0].priorityClass).toBeDefined();
    expect(datatable.data[0].recordLink).toBeDefined();
  });

  it("displays correct page info with data", async () => {
    const element = createElement("c-user-story-list", {
      is: UserStoryList
    });
    document.body.appendChild(element);

    getFeatures.emit(mockGetFeatures);
    getUserStories.emit(mockGetUserStories);
    await flushPromises();

    const pageInfo = element.shadowRoot.querySelector(".slds-text-body_small");
    expect(pageInfo).not.toBeNull();
    expect(pageInfo.textContent).toContain("of 50 user stories");
  });

  it("renders feature options from wire data", async () => {
    const element = createElement("c-user-story-list", {
      is: UserStoryList
    });
    document.body.appendChild(element);

    getFeatures.emit(mockGetFeatures);
    await flushPromises();

    getUserStories.emit(mockGetUserStories);
    await flushPromises();

    const datatable = element.shadowRoot.querySelector("lightning-datatable");
    expect(datatable).not.toBeNull();
  });

  it("emits error toast when wire emits error", async () => {
    const element = createElement("c-user-story-list", {
      is: UserStoryList
    });
    document.body.appendChild(element);

    const mockError = {
      body: { message: "Failed to fetch user stories" }
    };

    let toastEvent = null;
    element.addEventListener("lightning__showtoast", (event) => {
      toastEvent = event;
    });

    getUserStories.error(mockError);
    await flushPromises();

    expect(toastEvent).not.toBeNull();
    expect(toastEvent.detail.title).toBe("Error Loading User Stories");
    expect(toastEvent.detail.variant).toBe("error");
    expect(toastEvent.detail.mode).toBe("sticky");
  });

  it("datatable has sortable columns", async () => {
    const element = createElement("c-user-story-list", {
      is: UserStoryList
    });
    document.body.appendChild(element);

    getFeatures.emit(mockGetFeatures);
    getUserStories.emit(mockGetUserStories);
    await flushPromises();

    const datatable = element.shadowRoot.querySelector("lightning-datatable");
    expect(datatable.columns.some((col) => col.sortable)).toBe(true);
  });
});
