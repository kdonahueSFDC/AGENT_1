import { LightningElement, api } from 'lwc';

export default class LCC_CustomDataTableComboBox extends LightningElement {
     @api value;
     @api options;
     @api context;
     @api columnName;

     
     @api
     get validity() {
          return this.template.querySelector('lightning-combobox').validity;
     }

     @api
     reportValidity() {
          return this.template.querySelector('lightning-combobox').reportValidity();
     }

     @api
     checkValidity() {
          return this.template.querySelector('lightning-combobox').checkValidity();
     }

     @api
     setCustomValidity(message) {
          this.template.querySelector('lightning-combobox').setCustomValidity(message);
     }

     @api
     showHelpMessageIfInvalid() {
          this.template.querySelector('lightning-combobox').showHelpMessageIfInvalid();
     }

     handleChange(event) {
          const changeEvent = new CustomEvent('selectupdate', {
               composed: true,
               bubbles: true,
               cancelable: true,
               detail: {
                    context: this.context,
                    value: event.detail.value,
                    columnName: this.columnName
               }
          });
          this.dispatchEvent(changeEvent);
          this.template.querySelector('lightning-combobox').blur();
     }
}