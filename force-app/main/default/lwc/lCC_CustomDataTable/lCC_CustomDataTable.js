import { LightningElement, api } from 'lwc';

export default class LCC_CustomDataTable extends LightningElement {
     @api displayedRecords = [];
     
     @api pageSize;
     @api totalResultsSize;
     @api filteredResultsSize;
     @api keyField;
     @api preventReset = false;

     @api
     set columns(v) {
          this._columns = Array.isArray(v) ? [ ...v ] : [];
     }
     get columns() { return this._columns };
     @api
     set records(v) {
          this._records = Array.isArray(v) ? [ ...v ] : [];
          if (!this.preventReset) {
               this.resetPage();
               this.resetSort();
          }
          this.updateDisplayedRecords();
     }
     get records() { return this._records };

     get totalPages() { return Math.max(1, Math.ceil(this.totalItems / this.pageSize)) };
     get isFirstPage() { return this.currentPage <= 1 };
     get isLastPage() { return this.currentPage >= this.totalPages };
     get totalItems() { return this.records.length };
     get hasNoFilters() { return this.totalResultsSize == this.filteredResultsSize };
     get isRecordsEmpty() { return this.records.length < 1};

     currentPage = 1;
     displayedRecords = [];
     sortDirection = 'asc';
     sortedBy;

     handlePrevious = () => this.goTo(Math.max(1, this.currentPage - 1));
     handleNext = () => this.goTo(Math.min(this.totalPages, this.currentPage + 1));
     handleGoToPage = (e) => this.goTo(parseInt(e.currentTarget.dataset.page, 10));

     updateDisplayedRecords() {
          this.displayedRecords = [];
          const start = (this.currentPage - 1) * this.pageSize;
          const end = start + this.pageSize;
          this.displayedRecords = this.records.slice(start, end);
          this.recordsSize = this.displayedRecords.length;
     }

     resetPage() {
          this.currentPage = 1;
     }

     resetSort() {
          this.sortDirection = 'asc';
          this.sortedBy = null;
     }

     goTo(page) {
          const clamped = Math.min(Math.max(1, page), this.totalPages);
          if (clamped !== this.currentPage) {
               this.currentPage = clamped;
          }
          this.updateDisplayedRecords();
     }

     handleSort(event) {
          const { fieldName: sortedByField, sortDirection } = event.detail;
          const cloneData = [ ...this.records ];

          cloneData.sort(this.sortBy(sortedByField, sortDirection === 'asc' ? 1 : -1));
          this.records = [ ...cloneData ];
          this.sortDirection = sortDirection;
          this.sortedBy = sortedByField;
          this.resetPage();
          this.updateDisplayedRecords();
     }

     sortBy(field, reverse) {
          const key = (x) => field.toLowerCase().includes('date') ? Date.parse(x[field]) : field.includes('Url') ? x['name'] : x[field] + x['name'];
          return (a, b) => {
               a = key(a);
               b = key(b);

               a = a == undefined || a == null || a == 'null' || a == 0 ? 'zzz' : a;
               b = b == undefined || b == null || b == 'null' || b == 0 ? 'zzz' : b;
               if (field.toLowerCase().includes('date')) {
                    return reverse * ((a > b) - (b > a));
               }
               a = a.startsWith('null') ? a.replace('null', 'zzz') : a;
               b = b.startsWith('null') ? b.replace('null', 'zzz') : b;
               
               return reverse * ((a.toString().toLowerCase() > b.toString().toLowerCase()) - (b.toString().toLowerCase() > a.toString().toLowerCase()));
          };
     }

     /**
   * Build page items capped to 5 numbered buttons with ellipses.
   * Rules:
   * - totalPages <= 5: show all
   * - page <= 3:       1 2 3 4 … last
   * - page >= last-2:  1 … last-3 last-2 last-1 last
   * - middle:          1 … (page-1) page (page+1) … last
   */
     get pageItems() {
          const total = this.totalPages;
          const page = Math.min(Math.max(1, this.currentPage), total);

          let numbers = [];
          if (total <= 5) {
               numbers = Array.from({ length: total }, (_, i) => i + 1);
          } else if (page <= 3) {
               numbers = [ 1, 2, 3, 4, total ];
          } else if (page >= total - 2) {
               numbers = [ 1, total - 3, total - 2, total - 1, total ];
          } else {
               numbers = [ 1, page - 1, page, page + 1, total ];
          }

          const items = [];
          for (let i = 0; i < numbers.length; i++) {
               const n = numbers[ i ];
               if (i > 0) {
                    const prev = numbers[ i - 1 ];
                    if (n - prev > 1) {
                         items.push({ key: `dots-${i}`, isEllipsis: true });
                    }
               }
               const isCurrent = n === page;
               items.push({
                    key: `p-${n}`,
                    isEllipsis: false,
                    value: n,
                    label: String(n),
                    ariaCurrent: isCurrent ? 'page' : null,
                    buttonClass:
                         'slds-button slds-button_neutral ' +
                         (isCurrent ? 'slds-is-selected paginator__page--current' : 'paginator__page')
               });
          }
          return items;
     }
}