import { LightningElement, api } from 'lwc';
import { OmniscriptBaseMixin } from 'omnistudio/omniscriptBaseMixin';

export default class LCC_CustomTableQueryHandler extends OmniscriptBaseMixin(LightningElement) {
     @api
     set SEARCHTYPE(v) {
          this._searchType = (v && !v.startsWith('{')) ? v : null;
          this.initData();
     };
     get SEARCHTYPE() { return this._searchType; }
     @api
     set SEARCHARCHIVE(v) {
          this._searchArchive = (v == true || v == false) ? v : false;
          this.initData();
     };
     get SEARCHARCHIVE() { return this._searchArchive; }
     @api
     set SEARCHSTRING(v) {
          this._searchString = (v && !v.startsWith('{')) ? v : null;
          this.initData();
     };
     get SEARCHSTRING() { return this._searchString; }
     @api
     set SEARCHDATESTART(v) {
          this._searchDateStart = (v && !v.startsWith('{')) ? v : null;
          this.initData();
     };
     get SEARCHDATESTART() { return this._searchDateStart; }
     @api
     set SEARCHDATEEND(v) {
          this._searchDateEnd = (v && !v.startsWith('{')) ? v : null;
          this.initData();
     };
     get SEARCHDATEEND() { return this._searchDateEnd; }
     @api
     set SEARCHLICENSENUMBER(v) {
          this._searchLicenseNumber = (v && !v.startsWith('{')) ? v : null;
          this.initData();
     }
     get SEARCHLICENSENUMBER() { return this._searchLicenseNumber; }
     @api
     set SEARCHCITY(v) {
          this._searchCity = (v && !v.startsWith('{')) ? v : null;
          this.initData();
     }
     get SEARCHCITY() { return this._searchCity; }
     @api
     set SEARCHCOUNTY(v) {
          this._searchCounty = (v && !v.startsWith('{')) ? v : null;
          this.initData();
     }
     get SEARCHCOUNTY() { return this._searchCounty; }
     @api
     set SEARCHINSPECTIONRESULTS(v) {
          this._searchInspectionResults = (v && !v.startsWith('{')) ? v : null;
          this.initData();
     }
     get SEARCHINSPECTIONRESULTS() { return this._searchInspectionResults; }
     @api
     set SEARCHSTATUS(v) {
          this._searchStatus = (v && !v.startsWith('{')) ? v : null;
          this.initData();
     }
     get SEARCHSTATUS() { return this._searchStatus; }
     @api
     set SEARCHNAME(v) {
          this._searchName = (v && !v.startsWith('{')) ? v : null;
          this.initData();
     }
     get SEARCHNAME() { return this._searchName; }
     @api
     set SEARCHDISTNAME(v) {
          this._searchDistName = (v && !v.startsWith('{')) ? v : null;
          this.initData();
     }
     get SEARCHDISTNAME() { return this._searchDistName; }
     @api
     set SEARCHLICTYPE(v) {
          this._searchLicType = (v && !v.startsWith('{')) ? v : null;
          this.initData();
     }
     get SEARCHLICTYPE() { return this._searchLicType; }

     @api hideExport = false;

     records = [];
     columns = [];
     displayedRecords = [];
     waitingForQuery = false;
     totalResultsSize = 0;
     pageSize = 20;
     keyField;
     
     get isLoading() { return this.waitingForQuery };
     get filteredResultsSize() { return this.records.length };
     get showExport() { return !this.hideExport };


     initData() {
          if (!this.waitingForQuery && this.SEARCHTYPE && (this.SEARCHARCHIVE == true || this.SEARCHARCHIVE == false)) {
               this.waitingForQuery = true;
               setTimeout(() => { this.handleQueryTiming() }, 200);
          }
     }

     async handleQueryTiming() {
          if (!Array.isArray(this.columns) || this.columns.length < 1) {this.setColumns()};
          await this.getRecords();
          if (this.hasFilters()) this.handleFilters();
          this.waitingForQuery = false;
     }

     hasFilters() {
          return this.SEARCHSTRING || (this.SEARCHDATESTART && this.SEARCHDATESTART != 'null') || (this.SEARCHDATEEND && this.SEARCHDATEEND != 'null') ||
               this.SEARCHLICENSENUMBER || this.SEARCHCITY || this.SEARCHCOUNTY ||
               this.SEARCHINSPECTIONRESULTS || this.SEARCHSTATUS ? true : false || this.SEARCHNAME || this.SEARCHDISTNAME || this.SEARCHLICTYPE;
     }

     getRecords() {
          const inputData = {
               searchType: this.SEARCHTYPE,
               searchArchive: this.SEARCHARCHIVE
          };
          const params = {
               input: JSON.stringify(inputData),
               sClassName: 'omnistudio.IntegrationProcedureService',
               sMethodName: 'LCCSearch_HandleSearch',
               options: JSON.stringify({ chainable: true })
          };
          return this.omniRemoteCall(params, true)
               .then(response => {
                    this.records = [ ...response.result.IPResult.searchResults ];
                    this.totalResultsSize = this.records.length;
               })
               .catch(error => {
                    console.error('Error:', error.message);
               });
     }

     handleFilters() {
          this.records = this.records.filter(rec => {
               let matchesFilters = false;
               matchesFilters = this.filterSearchString(rec) && this.filterDateStart(rec) && this.filterDateEnd(rec) && this.filterLicenseNumber(rec) && this.filterCity(rec) && this.filterCounty(rec) && this.filterInspectionResults(rec) && this.filterStatus(rec) && this.filterName(rec) && this.filterDistName(rec) && this.filterLicType(rec);
               return matchesFilters;
          });
     }

     filterSearchString(rec) {
          if (this.SEARCHSTRING) {
               const { key, blUrl, blaUrl, ...rowData } = rec; // Remove key, blUrl, blaUrl and keep the rest
               const rowDataString = JSON.stringify(Object.values(rowData)); // Remove the keys, keep just the values
               return rowDataString?.toLowerCase().includes(this.SEARCHSTRING.toLowerCase());
          }
          return true;
     }

     filterDateStart(rec) {
          if (this.SEARCHDATESTART && this.SEARCHDATESTART != 'null') {
               const searchDateStartDate = new Date(this.SEARCHDATESTART);
               const dateDate = new Date(rec?.date);
               return searchDateStartDate <= dateDate;
          }
          return true;
     }

     filterDateEnd(rec) {
          if (this.SEARCHDATEEND && this.SEARCHDATEEND != 'null') {
               const searchDateEndDate = new Date(this.SEARCHDATEEND);
               const dateDate = new Date(rec?.date);
               return dateDate <= searchDateEndDate;
          }
          return true;
     }

     filterLicenseNumber(rec) {
          if (this.SEARCHLICENSENUMBER) {
               return rec?.licNumber?.toLowerCase().includes(this.SEARCHLICENSENUMBER.toLowerCase());
          }
          return true;
     }
     filterCity(rec) {
          if (this.SEARCHCITY) {
               return rec?.city?.toLowerCase().includes(this.SEARCHCITY.toLowerCase());
          }
          return true;
     }
     filterCounty(rec) {
          if (this.SEARCHCOUNTY) {
               return rec?.county?.toLowerCase().includes(this.SEARCHCOUNTY.toLowerCase());
          }
          return true;
     }
     filterInspectionResults(rec) {
          if (this.SEARCHINSPECTIONRESULTS) {
               return rec?.results?.toLowerCase() == this.SEARCHINSPECTIONRESULTS.toLowerCase();
          }
          return true;
     }
     filterStatus(rec) {
          if (this.SEARCHSTATUS) {
               return rec?.status?.toLowerCase() == this.SEARCHSTATUS.toLowerCase();
          }
          return true;
     }
     filterName(rec) {
          if (this.SEARCHNAME) {
               return rec?.name?.toLowerCase().includes(this.SEARCHNAME.toLowerCase());
          }
          return true;
     }
     filterDistName(rec) {
          if (this.SEARCHDISTNAME) {
               return rec?.distName?.toLowerCase().includes(this.SEARCHDISTNAME.toLowerCase());
          }
          return true;
     }
     filterLicType(rec) {
          if (this.SEARCHLICTYPE) {
               return rec?.licType?.toLowerCase().includes(this.SEARCHLICTYPE.toLowerCase());
          }
          return true;
     }

     setColumns() {
          if (this.SEARCHTYPE == 'licenseLookup') {
               this.columns = [
                    { "label": "ACCT. NAME", "fieldName": "blUrl", "type": "url", "typeAttributes": { "label": { "fieldName": "name" } }, "sortable": true },
                    { "label": "CORP. NAME", "fieldName": "corpName", "type": "text", "sortable": true },
                    { "label": "ADDRESS", "fieldName": "address", "type": "text", "sortable": true },
                    { "label": "LIC. NBR", "fieldName": "licNumber", "type": "text", "sortable": true },
                    { "label": "LIC. TYPE", "fieldName": "licType", "type": "text", "sortable": true },
                    { "label": "CITY", "fieldName": "city", "type": "text", "sortable": true },
                    { "label": "COUNTY", "fieldName": "county", "type": "text", "sortable": true },
                    { "label": "STATUS", "fieldName": "status", "type": "text", "sortable": true },
                    { "label": "EXPIR. DATE", "fieldName": "expDate", "type": "text", "sortable": true }
               ];
               this.keyField = 'key';
          } else if (this.SEARCHTYPE == 'underageCompliance') {
               this.columns = [
                    { "label": "DATE", "fieldName": "date", "type": "text", "sortable": true },
                    { "label": "LIC. NBR", "fieldName": "licNumber", "type": "text", "sortable": true },
                    { "label": "NAME", "fieldName": "name", "type": "text", "sortable": true },
                    { "label": "ADDRESS", "fieldName": "address", "type": "text", "sortable": true },
                    { "label": "CITY", "fieldName": "city", "type": "text", "sortable": true },
                    { "label": "COUNTY", "fieldName": "county", "type": "text", "sortable": true },
                    { "label": "RESULTS", "fieldName": "results", "type": "text", "sortable": true }

               ];
               this.keyField = 'key';
          } else if (this.SEARCHTYPE == 'deliquencyList') {
               this.columns = [
                    { "label": "DISTRIBUTOR'S BUSINESS NAME", "fieldName": "distName", "type": "text", "sortable": true },
                    { "label": "RETAILER BUSINESS NAME", "fieldName": "name", "type": "text", "sortable": true },
                    { "label": "RETAILER BUSINESS ADDRESS", "fieldName": "address", "type": "text", "sortable": true },
                    { "label": "RETAILER CITY", "fieldName": "city", "type": "text", "sortable": true },
                    { "label": "RETAILER IL LICENSE NBR", "fieldName": "licNumber", "type": "text", "sortable": true },
                    { "label": "DELINQUENCY DATE", "fieldName": "date", "type": "text", "sortable": true }

               ];
               this.keyField = 'key';
          } else if (this.SEARCHTYPE == 'cureList') {
               this.columns = [
                    { "label": "LIC NBR", "fieldName": "licNumber", "type": "text", "sortable": true },
                    { "label": "CORP NAME", "fieldName": "name", "type": "text", "sortable": true },
                    { "label": "ADDRESS", "fieldName": "address", "type": "text", "sortable": true },
                    { "label": "CITY", "fieldName": "city", "type": "text", "sortable": true },
                    { "label": "DATE", "fieldName": "date", "type": "text", "sortable": true }

               ];
               this.keyField = 'key';
          } else if (this.SEARCHTYPE == 'manufacturerPostings') {
               this.columns = [
                    { "label": "LIC TYPE NAME", "fieldName": "licType", "type": "text", "sortable": true },
                    { "label": "BUSINESS NAME", "fieldName": "blaUrl", "type": "url", "typeAttributes": { "label": { "fieldName": "name" } }, "sortable": true },
                    { "label": "FILING DATE", "fieldName": "date", "type": "text", "sortable": true }

               ];
               this.keyField = 'key';
          }
     }
}