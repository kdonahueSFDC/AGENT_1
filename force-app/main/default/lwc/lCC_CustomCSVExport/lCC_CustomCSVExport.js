import { LightningElement, api } from 'lwc';

export default class LCC_CustomCSVExport extends LightningElement {
     /** Array of row objects to export */
     @api data = [];
     @api
     set searchType(v) {
          this._searchType = (v && !v.startsWith('{')) ? v : null;
          if (this._searchType != null) {
               this.setColumns();
          }
     };
     get searchType() { return this._searchType; }

     @api columns = [];
     /** Optional file name */
     @api 
     get filename() { return this.searchType == 'licenseLookup' ? 'License Lookup.csv' : this.searchType == 'underageCompliance' ? 'Underage Compliance Results.csv' : this.searchType == 'deliquencyList' ? 'DelinquencyCure List.csv' : this.searchType == 'cureList' ? 'DelinquencyCure List.csv' : 'results.csv' };
     /** Button label */
     @api buttonLabel = 'Export to CSV';

     downloadLink;

     setColumns(){
          this.columns = this.searchType == 'licenseLookup' ? [
               { label: 'Acct. Name', fieldName: 'name' },
               { label: 'Corp. Name', fieldName: 'corpName' },
               { label: 'Corp. Addr', fieldName: 'address' },
               { label: 'Lic. Nbr', fieldName: 'licNumber' },
               { label: 'Lic. Type', fieldName: 'licType' },
               { label: 'County', fieldName: 'county' },
               { label: 'City', fieldName: 'city' },
               { label: 'County', fieldName: 'county' },
               { label: 'Status', fieldName: 'status' },
               { label: 'Expir. Date', fieldName: 'expDate' }
          ] : this.searchType == 'underageCompliance' ? [
               { label: 'Date', fieldName: 'date' },
               { label: 'Lic. Number', fieldName: 'licNumber' },
               { label: 'Name', fieldName: 'name' },
               { label: 'Address', fieldName: 'address' },
               { label: 'City', fieldName: 'city' },
               { label: 'County', fieldName: 'county' },
               { label: 'Results', fieldName: 'results' }
          ] : this.searchType == 'deliquencyList' ? [
               { label: 'Distributor\'s business name', fieldName: 'distName' },
               { label: 'Retailer Business Name', fieldName: 'name' },
               { label: 'Retailer Business address', fieldName: 'address' },
               { label: 'Retailer City', fieldName: 'city' },
               { label: 'Retailer IL Licnese nbr', fieldName: 'licNumber' },
               { label: 'Delinquency date', fieldName: 'date' }
          ] : this.searchType == 'cureList' ? [
               { label: 'LIC NBR', fieldName: 'licNumber' },
               { label: 'CORP NAME', fieldName: 'name' },
               { label: 'ADDRESS', fieldName: 'address' },
               { label: 'CITY', fieldName: 'city' },
               { label: 'DATE', fieldName: 'date' }
          ] : [
               { label: 'Name', fieldName: 'name' },
          ];
     }

     renderedCallback() {
          if (!this.downloadLink) {
               this.downloadLink = this.template.querySelector('.hidden-download');
          }
     }

     handleExport = () => {
          if (!Array.isArray(this.data) || this.data.length === 0) {
               this.downloadFile('\uFEFF' + this.columns.map(c => c.label || c.fieldName).join(',')); // headers only
               return;
          }
          const header = this.columns.map(c => c.label || c.fieldName);
          const csvRows = [ header ];

          for (const row of this.data) {
               const line = this.columns.map(col => {
                    const raw = this.getValue(row, col.fieldName);
                    const val = this.formatValue(raw, col.type);
                    return this.csvEscape(val);
               });
               csvRows.push(line);
          }

          // Add BOM for Excel + join
          const csv = '\uFEFF' + csvRows.map(r => r.join(',')).join('\n');
          this.downloadFile(csv);
     };

     getValue(obj, path) {
          if (!path) return '';
          return path.split('.').reduce((acc, key) => (acc && acc[ key ] !== undefined ? acc[ key ] : ''), obj);
     }

     formatValue(value, type) {
          if (value === null || value === undefined) return '';
          switch (type) {
               case 'date':
                    // Expecting ISO or Date; output YYYY-MM-DD for CSV friendliness
                    try {
                         const d = new Date(value);
                         if (!isNaN(d)) return d.toISOString().slice(0, 10);
                    } catch (e) { }
                    return value;
               default:
                    return String(value);
          }
     }

     csvEscape(val) {
          // Quote if contains comma, quote, or newline; escape double quotes
          const s = String(val);
          if (/[",\n]/.test(s)) {
               return `"${s.replace(/"/g, '""')}"`;
          }
          return s;
     }

     downloadFile(csvText) {
          const data = 'data:text/plain;charset=utf-8,' + encodeURIComponent(csvText);
          const a = this.template.querySelector('.hidden-download');
          a.href = data;
          a.download = this.filename || 'export.csv';
          a.target = '_self';
          a.rel = 'noopener';
          a.click();
     }
}
