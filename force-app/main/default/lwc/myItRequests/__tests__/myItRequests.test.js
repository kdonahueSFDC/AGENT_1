import { createElement } from "lwc";
import MyItRequests from "c/myItRequests";
import getMyRequests from "@salesforce/apex/MyITRequestsController.getMyRequests";

const mockTwoRequests = require("./data/twoRequests.json");
const mockEmptyRequests = require("./data/emptyRequests.json");

jest.mock(
  "@salesforce/apex/MyITRequestsController.getMyRequests",
  () => {
    const { createApexTestWireAdapter } = require("@salesforce/sfdx-lwc-jest");
    return {
      default: createApexTestWireAdapter(jest.fn())
    };
  },
  { virtual: true }
);

function flushPromises() {
  return Promise.resolve();
}

function setInputValue(element, selector, value) {
  const input = element.shadowRoot.querySelector(selector);
  input.value = value;
  input.dispatchEvent(new CustomEvent("change", { detail: { value } }));
  return input;
}

describe("c-my-it-requests", () => {
  afterEach(() => {
    while (document.body.firstChild) {
      document.body.removeChild(document.body.firstChild);
    }
    jest.clearAllMocks();
  });

  it("prompts for email before any search is triggered", () => {
    const element = createElement("c-my-it-requests", {
      is: MyItRequests
    });
    document.body.appendChild(element);

    const prompt = element.shadowRoot.querySelector("p");
    expect(prompt).not.toBeNull();
    expect(prompt.textContent).toMatch(/Enter your work email/);

    const datatable = element.shadowRoot.querySelector("lightning-datatable");
    expect(datatable).toBeNull();
  });

  it("renders datatable when the wire returns records", async () => {
    const element = createElement("c-my-it-requests", {
      is: MyItRequests
    });
    document.body.appendChild(element);

    setInputValue(element, "lightning-input", "alice@example.com");
    element.shadowRoot.querySelector("lightning-button").click();
    await flushPromises();

    getMyRequests.emit(mockTwoRequests);
    await flushPromises();

    const datatable = element.shadowRoot.querySelector("lightning-datatable");
    expect(datatable).not.toBeNull();
    expect(datatable.data.length).toBe(2);
    expect(datatable.data[0].name).toBe("IT-00001");
  });

  it("shows an empty summary when the wire returns zero records", async () => {
    const element = createElement("c-my-it-requests", {
      is: MyItRequests
    });
    document.body.appendChild(element);

    setInputValue(element, "lightning-input", "nobody@example.com");
    element.shadowRoot.querySelector("lightning-button").click();
    await flushPromises();

    getMyRequests.emit(mockEmptyRequests);
    await flushPromises();

    const paragraphs = element.shadowRoot.querySelectorAll("p");
    const summary = Array.from(paragraphs).find((p) =>
      /No requests found/.test(p.textContent)
    );
    expect(summary).toBeDefined();

    const datatable = element.shadowRoot.querySelector("lightning-datatable");
    expect(datatable).toBeNull();
  });

  it("shows error text when the wire emits an error", async () => {
    const element = createElement("c-my-it-requests", {
      is: MyItRequests
    });
    document.body.appendChild(element);

    setInputValue(element, "lightning-input", "alice@example.com");
    element.shadowRoot.querySelector("lightning-button").click();
    await flushPromises();

    getMyRequests.error({ body: { message: "boom" } });
    await flushPromises();

    const paragraphs = element.shadowRoot.querySelectorAll("p");
    const errorMsg = Array.from(paragraphs).find((p) =>
      /Something went wrong/.test(p.textContent)
    );
    expect(errorMsg).toBeDefined();
  });

  it("blocks search when email input fails reportValidity", async () => {
    const element = createElement("c-my-it-requests", {
      is: MyItRequests
    });
    document.body.appendChild(element);

    setInputValue(element, "lightning-input", "test@example.com");
    await flushPromises();

    const input = element.shadowRoot.querySelector("lightning-input");
    const mockReportValidity = jest.fn(() => false);
    input.reportValidity = mockReportValidity;

    const originalQuerySelector = element.shadowRoot.querySelector.bind(
      element.shadowRoot
    );
    element.shadowRoot.querySelector = jest.fn((selector) => {
      if (selector === 'lightning-input[type="email"]') {
        return input;
      }
      return originalQuerySelector(selector);
    });

    element.shadowRoot.querySelector("lightning-button").click();
    await flushPromises();

    expect(mockReportValidity).toHaveBeenCalled();

    const datatable = originalQuerySelector("lightning-datatable");
    expect(datatable).toBeNull();

    const paragraphs = originalQuerySelector.call(element.shadowRoot, "p");
    expect(paragraphs).not.toBeNull();
    expect(paragraphs.textContent).toMatch(/Enter your work email/);
  });
});
