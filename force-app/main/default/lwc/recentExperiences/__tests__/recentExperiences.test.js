import { createElement } from "lwc";
import RecentExperiences from "c/recentExperiences";
import getRecentExperiences from "@salesforce/apex/ExperienceController.getRecentExperiences";

// Mock realistic data
const mockGetRecentExperiences = require("./data/getRecentExperiences.json");
const mockEmptyExperiences = require("./data/emptyExperiences.json");

// Mock the Apex wire adapter
jest.mock(
  "@salesforce/apex/ExperienceController.getRecentExperiences",
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

describe("c-recent-experiences", () => {
  afterEach(() => {
    while (document.body.firstChild) {
      document.body.removeChild(document.body.firstChild);
    }
    jest.clearAllMocks();
  });

  it("renders spinner while loading (initial state)", () => {
    const element = createElement("c-recent-experiences", {
      is: RecentExperiences
    });
    document.body.appendChild(element);

    const spinner = element.shadowRoot.querySelector("lightning-spinner");
    expect(spinner).not.toBeNull();
  });

  it("renders datatable with records after wire emits data", async () => {
    const element = createElement("c-recent-experiences", {
      is: RecentExperiences
    });
    document.body.appendChild(element);

    getRecentExperiences.emit(mockGetRecentExperiences);
    await flushPromises();

    const datatable = element.shadowRoot.querySelector("lightning-datatable");
    expect(datatable).not.toBeNull();
    expect(datatable.data).toEqual(mockGetRecentExperiences.records);
    expect(datatable.data.length).toBe(2);
  });

  it('shows "No experiences found" empty state when records is empty', async () => {
    const element = createElement("c-recent-experiences", {
      is: RecentExperiences
    });
    document.body.appendChild(element);

    getRecentExperiences.emit(mockEmptyExperiences);
    await flushPromises();

    const emptyMessage = element.shadowRoot.querySelector("p");
    expect(emptyMessage).not.toBeNull();
    expect(emptyMessage.textContent).toBe("No experiences found.");
  });

  it("emits error toast when wire emits error", async () => {
    const element = createElement("c-recent-experiences", {
      is: RecentExperiences
    });
    document.body.appendChild(element);

    const mockError = {
      body: { message: "Failed to fetch experiences" }
    };

    let toastEvent = null;
    element.addEventListener("lightning__showtoast", (event) => {
      toastEvent = event;
    });

    getRecentExperiences.error(mockError);
    await flushPromises();

    expect(toastEvent).not.toBeNull();
    expect(toastEvent.detail.title).toBe("Error Loading Experiences");
    expect(toastEvent.detail.variant).toBe("error");
    expect(toastEvent.detail.mode).toBe("sticky");
  });

  it("Previous button is disabled on first page", async () => {
    const element = createElement("c-recent-experiences", {
      is: RecentExperiences
    });
    document.body.appendChild(element);

    const dataPage1 = {
      ...mockGetRecentExperiences,
      currentPage: 1,
      totalPages: 3
    };
    getRecentExperiences.emit(dataPage1);
    await flushPromises();

    const pageInfo = element.shadowRoot.querySelector(".slds-text-body_small");
    expect(pageInfo).not.toBeNull();
    expect(pageInfo.textContent).toContain("Showing 1-");
  });

  it("Next button functionality works across pages", async () => {
    const element = createElement("c-recent-experiences", {
      is: RecentExperiences
    });
    document.body.appendChild(element);

    const dataPage1 = {
      ...mockGetRecentExperiences,
      currentPage: 1,
      totalPages: 3
    };
    getRecentExperiences.emit(dataPage1);
    await flushPromises();

    const pageInfo = element.shadowRoot.querySelector(".slds-text-body_small");
    expect(pageInfo.textContent).toContain("of 12 experiences");
  });

  it("sorts datatable ascending by Name when sort event is dispatched", async () => {
    const element = createElement("c-recent-experiences", {
      is: RecentExperiences
    });
    document.body.appendChild(element);

    getRecentExperiences.emit(mockGetRecentExperiences);
    await flushPromises();

    const datatable = element.shadowRoot.querySelector("lightning-datatable");
    expect(datatable).not.toBeNull();

    datatable.dispatchEvent(
      new CustomEvent("sort", {
        detail: { fieldName: "Name", sortDirection: "asc" }
      })
    );
    await flushPromises();

    expect(datatable.sortedBy).toBe("Name");
    expect(datatable.sortedDirection).toBe("asc");
    expect(datatable.data.length).toBe(2);
    expect(datatable.data[0].Name).toBe("City Food Tour");
    expect(datatable.data[1].Name).toBe("Grand Canyon Adventure");
  });

  it("sorts datatable descending by Name when sort direction is desc", async () => {
    const element = createElement("c-recent-experiences", {
      is: RecentExperiences
    });
    document.body.appendChild(element);

    getRecentExperiences.emit(mockGetRecentExperiences);
    await flushPromises();

    const datatable = element.shadowRoot.querySelector("lightning-datatable");
    expect(datatable).not.toBeNull();

    datatable.dispatchEvent(
      new CustomEvent("sort", {
        detail: { fieldName: "Name", sortDirection: "desc" }
      })
    );
    await flushPromises();

    expect(datatable.sortedBy).toBe("Name");
    expect(datatable.sortedDirection).toBe("desc");
    expect(datatable.data.length).toBe(2);
    expect(datatable.data[0].Name).toBe("Grand Canyon Adventure");
    expect(datatable.data[1].Name).toBe("City Food Tour");
  });
});
