// Simple script to create minimal test data for Feature__c and User_Story__c
// Execute in Developer Console: Execute Anonymous Window
// Or via CLI: sfdx force:apex:execute -f scripts/apex/create_simple_test_data.apex

// Create 2 simple Feature records
Feature__c feature1 = new Feature__c(
    Name = 'User Login Feature',
    Description__c = 'Enable users to log in securely to the application',
    Status__c = 'In_Progress'
);

Feature__c feature2 = new Feature__c(
    Name = 'Dashboard Widgets',
    Description__c = 'Display key metrics and charts on the dashboard',
    Status__c = 'Draft'
);

insert new List<Feature__c>{ feature1, feature2 };

// Get current user for assignment
Id currentUserId = UserInfo.getUserId();

// Create 5 simple User Story records
List<User_Story__c> stories = new List<User_Story__c>{
    new User_Story__c(
        Name = 'Create login form',
        Description__c = 'Build the login form UI with email and password fields',
        Status__c = 'Done',
        Priority__c = 'High',
        Feature__c = feature1.Id,
        Assignee__c = currentUserId,
        Acceptance_Criteria__c = 'Form validates input and displays error messages'
    ),
    new User_Story__c(
        Name = 'Add password reset',
        Description__c = 'Implement password reset email flow',
        Status__c = 'In_Progress',
        Priority__c = 'High',
        Feature__c = feature1.Id,
        Assignee__c = currentUserId,
        Acceptance_Criteria__c = 'User receives reset email and can set new password'
    ),
    new User_Story__c(
        Name = 'Build sales chart widget',
        Description__c = 'Create widget showing sales trends over time',
        Status__c = 'In_Review',
        Priority__c = 'Medium',
        Feature__c = feature2.Id,
        Assignee__c = currentUserId,
        Acceptance_Criteria__c = 'Chart displays last 30 days of sales data'
    ),
    new User_Story__c(
        Name = 'Add revenue metric widget',
        Description__c = 'Show total revenue and growth percentage',
        Status__c = 'Backlog',
        Priority__c = 'Medium',
        Feature__c = feature2.Id,
        Acceptance_Criteria__c = 'Widget updates daily with latest revenue data'
    ),
    new User_Story__c(
        Name = 'Implement widget drag and drop',
        Description__c = 'Allow users to rearrange dashboard widgets',
        Status__c = 'Blocked',
        Priority__c = 'Low',
        Feature__c = feature2.Id,
        Acceptance_Criteria__c = 'Widgets can be moved and positions are saved'
    )
};

insert stories;

System.debug('Successfully created test data:');
System.debug('  - 2 Features');
System.debug('  - 5 User Stories');







