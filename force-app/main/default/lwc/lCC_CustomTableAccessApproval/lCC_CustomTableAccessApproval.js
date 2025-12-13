import { LightningElement, api } from 'lwc';
import { OmniscriptBaseMixin } from 'omnistudio/omniscriptBaseMixin';

export default class LCC_CustomTableAccessApproval extends OmniscriptBaseMixin(LightningElement) {     
     @api
     set SEARCHTYPE(v) {
          this._searchType = (v && !v.startsWith('{')) ? v : null;
          this.initData();
     };
     get SEARCHTYPE() { return this._searchType; }
     @api
     set RECORDSINPUT(v) {
          if (Array.isArray(v) && v.length > 0) {
               this._recordsInput = [...v];
          }
     };
     get RECORDSINPUT() { return this._recordsInput; }
     
     records = [];
     columns = [];
     preventReset = true;
     displayedRecords = [];
     waitingForQuery = false;
     totalResultsSize = 0;
     pageSize = 5;
     keyField;
     
     get isLoading() { return this.waitingForQuery };
     get filteredResultsSize() { return this.records.length };

     initData() {
          setTimeout(() => { this.handleQueryTiming() }, 500);
     }

     async handleQueryTiming() {
          this.waitingForQuery = true;
          if (!Array.isArray(this.columns) || this.columns.length < 1) {this.setColumns()};
          if (Array.isArray(this.RECORDSINPUT) && this.RECORDSINPUT.length > 0) {
               this.records = [...this.RECORDSINPUT];
          } else {
               await this.getRecords();
          };
          this.waitingForQuery = false;
     }

     getRecords() {
          const inputData = {
               searchType: this.SEARCHTYPE
          };
          const params = {
               input: JSON.stringify(inputData),
               sClassName: 'omnistudio.IntegrationProcedureService',
               sMethodName: 'LCCAccountRegistration_GetAccessRequestsPendingApprovalByMasterUsers',
               options: JSON.stringify({ chainable: true })
          };
          return this.omniRemoteCall(params, true)
               .then(response => {
                    this.records = [ ...response.result.IPResult.searchResults ];
                    this.records = this.records.map(x => { return { ...x, ApproveReject: null } })
                    this.totalResultsSize = this.records.length;
               })
               .catch(error => {
                    console.error('Error:', error.message);
               });
     }

     handleSelectUpdate(e) {
          // context -- which row to update (key). This should be provided by column config (see below)
          // columnName -- which key/value pair to update. This should be provided by column config (see below)
          this.records = this.records.map(x => {
               const tempRecords = {...x};
               if (x.Id == e.detail.context) {
                    tempRecords[e.detail.columnName] = e.detail.value;
               }
               return tempRecords;
          })
          this.fireUpdate();
     }

     fireUpdate() {
          const omniRecords = this.records.filter(x => x.ApproveReject !== null)
          this.omniApplyCallResp({
               selectedAccessRequests: omniRecords,
               records: this.records
          });
          
     }

     setColumns() {
               this.columns = [
                    { "label": "Business Account", "fieldName": "AccountName", "type": "text", "sortable": false },
                    { "label": "User", "fieldName": "UserName", "type": "text", "sortable": false },
                    { "label": "User Email", "fieldName": "UserEmail", "type": "text", "sortable": false },
                    { "label": "Access Level", "type": "customSelect", "editable": true,
                         "typeAttributes": {
                              "context": { "fieldName": "Id" },
                              "options": [
                                   { label: 'Master', value: 'Master' },
                                   { label: 'Delegated', value: 'Delegated' },
                                   { label: 'Read Only', value: 'Read Only' }
                              ],
                              "value": { "fieldName": "AccessLevel" },
                              "columnName": "AccessLevel",
                              "iconName": "utility:approval",
                              "displayBadge": true
                         }
                    },
                    { "label": "Approve/Reject", "type": "customSelect", "editable": true,
                         "typeAttributes": {
                              "context": { "fieldName": "Id" },
                              "options": [
                                   { label: 'Approve', value: 'APPROVE' },
                                   { label: 'Reject', value: 'REJECT' },
                                   { label: ' -- Clear -- ', value: null }
                                   
                              ],
                              "value": { "fieldName": "ApproveReject" },
                              "columnName": "ApproveReject",
                              "displayBadge": true
                         }
                    }
               ];
               this.keyField = 'Id';
     }
}