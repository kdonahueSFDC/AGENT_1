import { LightningElement, api } from "lwc";

import customSelectTemplate from "./customSelect.html";
import customSelectEditTemplate from "./customSelectEdit.html";

export default class LCC_CustomDataTableTypesProvider extends LightningElement {
  @api
  getDataTypes() {
    return {
      customSelect: {
        template: customSelectTemplate,
        editTemplate: customSelectEditTemplate,
        standardCellLayout: true,
        typeAttributes: ["options", "value", "min", "context", "columnName", "iconName", "displayBadge"]
        // min: do not set this at all
        // context: which row to update (same as keyField)
        // columnName: which key/value pair to update
        // iconName: provide slds icon name to display icon if using displayBadge
        // displayBadge: set to true to utilize badges instead of just diplaying text
      }
    };
  }
}