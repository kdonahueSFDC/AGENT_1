/**
 * @description Controller class for Experience__c object queries
 * @author Salesforce (Cursor)
 * @date 2025-12-08
 */
public with sharing class ExperienceController {
    
    /**
     * @description Retrieves recent experiences with pagination
     * @param pageNumber Current page number (1-based)
     * @param pageSize Number of records per page
     * @return PaginatedResult containing experiences and total count
     */
    @AuraEnabled(cacheable=true)
    public static PaginatedResult getRecentExperiences(Integer pageNumber, Integer pageSize) {
        // Validate inputs
        if (pageNumber == null || pageNumber < 1) {
            pageNumber = 1;
        }
        if (pageSize == null || pageSize < 1) {
            pageSize = 5;
        }
        
        // Calculate offset
        Integer offset = (pageNumber - 1) * pageSize;
        
        // Query total count
        Integer totalRecords = [
            SELECT COUNT()
            FROM Experience__c
            WITH SECURITY_ENFORCED
        ];
        
        // Query paginated records
        List<Experience__c> experiences = [
            SELECT Id, Name, Description__c, Location__c, Price__c, 
                   Type__c, Capacity__c, Rating__c, CreatedDate,
                   Picture_URL__c, Activity_Level__c, Duration_Hours__c
            FROM Experience__c
            WITH SECURITY_ENFORCED
            ORDER BY CreatedDate DESC
            LIMIT :pageSize
            OFFSET :offset
        ];
        
        // Calculate total pages
        Integer totalPages = (Integer)Math.ceil((Double)totalRecords / pageSize);
        
        return new PaginatedResult(experiences, totalRecords, totalPages, pageNumber, pageSize);
    }
    
    /**
     * @description Wrapper class for paginated results
     */
    public class PaginatedResult {
        @AuraEnabled public List<Experience__c> records;
        @AuraEnabled public Integer totalRecords;
        @AuraEnabled public Integer totalPages;
        @AuraEnabled public Integer currentPage;
        @AuraEnabled public Integer pageSize;
        
        public PaginatedResult(
            List<Experience__c> records,
            Integer totalRecords,
            Integer totalPages,
            Integer currentPage,
            Integer pageSize
        ) {
            this.records = records;
            this.totalRecords = totalRecords;
            this.totalPages = totalPages;
            this.currentPage = currentPage;
            this.pageSize = pageSize;
        }
    }
}

