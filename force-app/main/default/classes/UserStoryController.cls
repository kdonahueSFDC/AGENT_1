/**
 * @description Controller class for User_Story__c object queries and updates
 * @author Salesforce (Cursor)
 * @date 2025-12-08
 */
public with sharing class UserStoryController {
    
    // Valid status values for validation
    private static final Set<String> VALID_STATUSES = new Set<String>{
        'Backlog', 'In_Progress', 'In_Review', 'Done', 'Blocked'
    };
    
    /**
     * @description Retrieves user stories with optional filtering and pagination
     * @param featureId Optional Feature__c Id to filter by
     * @param status Optional Status__c value to filter by
     * @param priority Optional Priority__c value to filter by
     * @param assigneeId Optional User Id to filter by assignee
     * @param pageNumber Current page number (1-based)
     * @param pageSize Number of records per page
     * @param sortBy Field name to sort by (default: Name)
     * @param sortDirection Sort direction: 'asc' or 'desc' (default: 'asc')
     * @return PaginatedResult containing user stories and pagination metadata
     */
    @AuraEnabled(cacheable=true)
    public static PaginatedResult getUserStories(
        String featureId,
        String status,
        String priority,
        String assigneeId,
        Integer pageNumber,
        Integer pageSize,
        String sortBy,
        String sortDirection
    ) {
        // Validate and set defaults for pagination
        if (pageNumber == null || pageNumber < 1) {
            pageNumber = 1;
        }
        if (pageSize == null || pageSize < 1) {
            pageSize = 50;
        }
        if (pageSize > 200) {
            pageSize = 200; // Enforce maximum page size
        }
        
        // Validate and set defaults for sorting
        if (String.isBlank(sortBy)) {
            sortBy = 'Name';
        }
        if (String.isBlank(sortDirection) || 
            (sortDirection != 'asc' && sortDirection != 'desc')) {
            sortDirection = 'asc';
        }
        
        // Calculate offset
        Integer offset = (pageNumber - 1) * pageSize;
        
        // Build WHERE clause
        String whereClause = buildWhereClause(featureId, status, priority, assigneeId);
        
        // Build ORDER BY clause with validation
        String orderByClause = buildOrderByClause(sortBy, sortDirection);
        
        // Query total count
        String countQuery = 'SELECT COUNT() FROM User_Story__c' + whereClause + ' WITH SECURITY_ENFORCED';
        Integer totalRecords = Database.countQuery(countQuery);
        
        // Query paginated records
        String query = 'SELECT Id, Name, Description__c, Status__c, Priority__c, ' +
                      'Assignee__c, Assignee__r.Name, Assignee__r.Id, ' +
                      'Feature__c, Feature__r.Name, Feature__r.Id, ' +
                      'Acceptance_Criteria__c, CreatedDate, LastModifiedDate ' +
                      'FROM User_Story__c' + whereClause + 
                      ' WITH SECURITY_ENFORCED' + orderByClause +
                      ' LIMIT :pageSize OFFSET :offset';
        
        List<User_Story__c> userStories = Database.query(query);
        
        // Calculate total pages
        Integer totalPages = (Integer)Math.ceil((Double)totalRecords / pageSize);
        
        return new PaginatedResult(userStories, totalRecords, totalPages, pageNumber, pageSize);
    }
    
    /**
     * @description Retrieves user stories grouped by status for Kanban board
     * @param featureId Optional Feature__c Id to filter by
     * @return Map of status values to lists of user stories
     */
    @AuraEnabled(cacheable=true)
    public static Map<String, List<UserStoryWrapper>> getUserStoriesByStatus(String featureId) {
        Map<String, List<UserStoryWrapper>> storiesByStatus = new Map<String, List<UserStoryWrapper>>();
        
        // Initialize all status columns
        for (String status : VALID_STATUSES) {
            storiesByStatus.put(status, new List<UserStoryWrapper>());
        }
        
        // Build WHERE clause
        String whereClause = buildWhereClause(featureId, null, null, null);
        
        // Query all user stories
        String query = 'SELECT Id, Name, Description__c, Status__c, Priority__c, ' +
                      'Assignee__c, Assignee__r.Name, Assignee__r.Id, ' +
                      'Feature__c, Feature__r.Name, Feature__r.Id, ' +
                      'Acceptance_Criteria__c, CreatedDate, LastModifiedDate ' +
                      'FROM User_Story__c' + whereClause + 
                      ' WITH SECURITY_ENFORCED ' +
                      'ORDER BY Priority__c DESC NULLS LAST, Name ASC';
        
        List<User_Story__c> userStories = Database.query(query);
        
        // Group by status
        for (User_Story__c story : userStories) {
            String storyStatus = story.Status__c != null ? story.Status__c : 'Backlog';
            if (!storiesByStatus.containsKey(storyStatus)) {
                storiesByStatus.put(storyStatus, new List<UserStoryWrapper>());
            }
            storiesByStatus.get(storyStatus).add(new UserStoryWrapper(story));
        }
        
        return storiesByStatus;
    }
    
    /**
     * @description Updates the status of a user story (for Kanban drag-and-drop)
     * @param storyId User_Story__c record Id
     * @param newStatus New status value
     * @return Updated User_Story__c record
     */
    @AuraEnabled
    public static UserStoryWrapper updateUserStoryStatus(Id storyId, String newStatus) {
        // Validate inputs
        if (storyId == null) {
            throw new AuraHandledException('Story Id is required');
        }
        if (String.isBlank(newStatus)) {
            throw new AuraHandledException('Status is required');
        }
        if (!VALID_STATUSES.contains(newStatus)) {
            throw new AuraHandledException('Invalid status value: ' + newStatus);
        }
        
        try {
            // Query the record to ensure user has access
            List<User_Story__c> stories = [
                SELECT Id, Name, Description__c, Status__c, Priority__c,
                       Assignee__c, Assignee__r.Name, Assignee__r.Id,
                       Feature__c, Feature__r.Name, Feature__r.Id,
                       Acceptance_Criteria__c, CreatedDate, LastModifiedDate
                FROM User_Story__c
                WHERE Id = :storyId
                WITH SECURITY_ENFORCED
                LIMIT 1
            ];
            
            if (stories.isEmpty()) {
                throw new AuraHandledException('User story not found or access denied');
            }
            
            User_Story__c story = stories[0];
            story.Status__c = newStatus;
            
            // Update with user-mode DML to respect FLS and sharing at DML time
            Database.update(story, AccessLevel.USER_MODE);
            
            // Re-query to get fresh data including LastModifiedDate
            List<User_Story__c> updatedStories = [
                SELECT Id, Name, Description__c, Status__c, Priority__c,
                       Assignee__c, Assignee__r.Name, Assignee__r.Id,
                       Feature__c, Feature__r.Name, Feature__r.Id,
                       Acceptance_Criteria__c, CreatedDate, LastModifiedDate
                FROM User_Story__c
                WHERE Id = :storyId
                WITH SECURITY_ENFORCED
                LIMIT 1
            ];
            
            if (updatedStories.isEmpty()) {
                throw new AuraHandledException('User story not found after update');
            }
            
            // Return updated record
            return new UserStoryWrapper(updatedStories[0]);
            
        } catch (DmlException e) {
            throw new AuraHandledException('Failed to update user story: ' + e.getMessage());
        } catch (Exception e) {
            throw new AuraHandledException('Error updating user story: ' + e.getMessage());
        }
    }
    
    /**
     * @description Retrieves all features for filtering dropdowns
     * @return List of Feature__c records with Id and Name
     */
    @AuraEnabled(cacheable=true)
    public static List<FeatureWrapper> getFeatures() {
        List<Feature__c> features = [
            SELECT Id, Name, Status__c, Description__c
            FROM Feature__c
            WITH SECURITY_ENFORCED
            ORDER BY Name ASC
        ];
        
        List<FeatureWrapper> wrappers = new List<FeatureWrapper>();
        for (Feature__c feature : features) {
            wrappers.add(new FeatureWrapper(feature));
        }
        
        return wrappers;
    }
    
    /**
     * @description Builds WHERE clause for SOQL queries
     * @param featureId Optional Feature__c Id
     * @param status Optional Status__c value
     * @param priority Optional Priority__c value
     * @param assigneeId Optional User Id
     * @return WHERE clause string (empty if no filters)
     */
    private static String buildWhereClause(
        String featureId,
        String status,
        String priority,
        String assigneeId
    ) {
        List<String> conditions = new List<String>();
        
        if (String.isNotBlank(featureId)) {
            conditions.add('Feature__c = :featureId');
        }
        if (String.isNotBlank(status)) {
            conditions.add('Status__c = :status');
        }
        if (String.isNotBlank(priority)) {
            conditions.add('Priority__c = :priority');
        }
        if (String.isNotBlank(assigneeId)) {
            conditions.add('Assignee__c = :assigneeId');
        }
        
        if (conditions.isEmpty()) {
            return '';
        }
        
        return ' WHERE ' + String.join(conditions, ' AND ');
    }
    
    /**
     * @description Builds ORDER BY clause with field validation
     * @param sortBy Field name to sort by
     * @param sortDirection Sort direction
     * @return ORDER BY clause string
     */
    private static String buildOrderByClause(String sortBy, String sortDirection) {
        // Whitelist of allowed sort fields for security
        Set<String> allowedSortFields = new Set<String>{
            'Name', 'Status__c', 'Priority__c', 'CreatedDate', 'LastModifiedDate',
            'Feature__r.Name', 'Assignee__r.Name'
        };
        
        // Validate sort field
        if (!allowedSortFields.contains(sortBy)) {
            sortBy = 'Name';
        }
        
        return ' ORDER BY ' + sortBy + ' ' + sortDirection.toUpperCase();
    }
    
    /**
     * @description Wrapper class for paginated results
     */
    public class PaginatedResult {
        @AuraEnabled public List<UserStoryWrapper> records;
        @AuraEnabled public Integer totalRecords;
        @AuraEnabled public Integer totalPages;
        @AuraEnabled public Integer currentPage;
        @AuraEnabled public Integer pageSize;
        
        public PaginatedResult(
            List<User_Story__c> stories,
            Integer totalRecords,
            Integer totalPages,
            Integer currentPage,
            Integer pageSize
        ) {
            this.records = new List<UserStoryWrapper>();
            for (User_Story__c story : stories) {
                this.records.add(new UserStoryWrapper(story));
            }
            this.totalRecords = totalRecords;
            this.totalPages = totalPages;
            this.currentPage = currentPage;
            this.pageSize = pageSize;
        }
    }
    
    /**
     * @description Wrapper class for User_Story__c records with related field data
     */
    public class UserStoryWrapper {
        @AuraEnabled public Id id;
        @AuraEnabled public String name;
        @AuraEnabled public String description;
        @AuraEnabled public String status;
        @AuraEnabled public String priority;
        @AuraEnabled public Id assigneeId;
        @AuraEnabled public String assigneeName;
        @AuraEnabled public Id featureId;
        @AuraEnabled public String featureName;
        @AuraEnabled public String acceptanceCriteria;
        @AuraEnabled public DateTime createdDate;
        @AuraEnabled public DateTime lastModifiedDate;
        
        public UserStoryWrapper(User_Story__c story) {
            this.id = story.Id;
            this.name = story.Name;
            this.description = story.Description__c;
            this.status = story.Status__c;
            this.priority = story.Priority__c;
            this.acceptanceCriteria = story.Acceptance_Criteria__c;
            this.createdDate = story.CreatedDate;
            this.lastModifiedDate = story.LastModifiedDate;
            
            // Handle assignee relationship
            if (story.Assignee__c != null) {
                this.assigneeId = story.Assignee__c;
                this.assigneeName = story.Assignee__r != null ? story.Assignee__r.Name : null;
            }
            
            // Handle feature relationship
            if (story.Feature__c != null) {
                this.featureId = story.Feature__c;
                this.featureName = story.Feature__r != null ? story.Feature__r.Name : null;
            }
        }
    }
    
    /**
     * @description Wrapper class for Feature__c records
     */
    public class FeatureWrapper {
        @AuraEnabled public Id id;
        @AuraEnabled public String name;
        @AuraEnabled public String status;
        @AuraEnabled public String description;
        
        public FeatureWrapper(Feature__c feature) {
            this.id = feature.Id;
            this.name = feature.Name;
            this.status = feature.Status__c;
            this.description = feature.Description__c;
        }
    }
}
