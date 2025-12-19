// Script to create test data for Feature__c and User_Story__c objects
// Execute this in Developer Console or via: sfdx force:apex:execute -f scripts/apex/create_test_data.apex

// Create Feature records
List<Feature__c> features = new List<Feature__c>{
    new Feature__c(
        Name = 'User Authentication System',
        Description__c = 'Implement secure user authentication with multi-factor authentication support. This feature will provide login, registration, password reset, and session management capabilities.',
        Status__c = 'In_Progress'
    ),
    new Feature__c(
        Name = 'Dashboard Analytics',
        Description__c = 'Create a comprehensive analytics dashboard with real-time metrics, charts, and data visualization. Includes export functionality and customizable widgets.',
        Status__c = 'Draft'
    ),
    new Feature__c(
        Name = 'Mobile App Integration',
        Description__c = 'Build REST API endpoints and SDK for mobile application integration. Supports iOS and Android platforms with offline sync capabilities.',
        Status__c = 'In_Progress'
    ),
    new Feature__c(
        Name = 'Notification System',
        Description__c = 'Implement real-time notification system with email, SMS, and in-app notifications. Includes preference management and notification history.',
        Status__c = 'Completed'
    )
};

insert features;

System.debug('Created ' + features.size() + ' Feature records');

// Get current user for assignee
User currentUser = [SELECT Id, Name FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];

// Create User Story records linked to features
List<User_Story__c> userStories = new List<User_Story__c>();

// User Stories for "User Authentication System"
userStories.add(new User_Story__c(
    Name = 'Implement login page UI',
    Description__c = 'Create the login page with email/password fields, remember me checkbox, and forgot password link. Follow SLDS design system guidelines.',
    Status__c = 'Done',
    Priority__c = 'High',
    Feature__c = features[0].Id,
    Assignee__c = currentUser.Id,
    Acceptance_Criteria__c = '1. Login form displays correctly on all screen sizes\n2. Form validation works for empty fields\n3. Error messages display appropriately\n4. Accessibility requirements met (WCAG 2.2 AA)'
));

userStories.add(new User_Story__c(
    Name = 'Add password reset functionality',
    Description__c = 'Implement password reset flow: user requests reset, receives email with token, enters new password. Include security measures like token expiration.',
    Status__c = 'In_Progress',
    Priority__c = 'High',
    Feature__c = features[0].Id,
    Assignee__c = currentUser.Id,
    Acceptance_Criteria__c = '1. Reset email sent within 2 minutes\n2. Token expires after 1 hour\n3. Password meets complexity requirements\n4. Success confirmation displayed'
));

userStories.add(new User_Story__c(
    Name = 'Implement MFA setup',
    Description__c = 'Add multi-factor authentication setup flow. Users can enable MFA using authenticator apps or SMS. Include backup codes.',
    Status__c = 'In_Review',
    Priority__c = 'Critical',
    Feature__c = features[0].Id,
    Assignee__c = currentUser.Id,
    Acceptance_Criteria__c = '1. QR code displays for authenticator setup\n2. SMS verification works\n3. Backup codes generated and displayed\n4. MFA can be disabled with password confirmation'
));

userStories.add(new User_Story__c(
    Name = 'Add session management',
    Description__c = 'Implement session timeout, concurrent session limits, and session activity tracking. Users can view active sessions and revoke access.',
    Status__c = 'Backlog',
    Priority__c = 'Medium',
    Feature__c = features[0].Id,
    Acceptance_Criteria__c = '1. Sessions timeout after 30 minutes of inactivity\n2. Maximum 5 concurrent sessions per user\n3. Active sessions list displays correctly\n4. Revoke session functionality works'
));

// User Stories for "Dashboard Analytics"
userStories.add(new User_Story__c(
    Name = 'Create dashboard layout',
    Description__c = 'Design and implement the main dashboard layout with widget containers, drag-and-drop positioning, and responsive grid system.',
    Status__c = 'In_Progress',
    Priority__c = 'High',
    Feature__c = features[1].Id,
    Assignee__c = currentUser.Id,
    Acceptance_Criteria__c = '1. Dashboard loads in under 2 seconds\n2. Widgets can be repositioned\n3. Layout saves automatically\n4. Responsive on mobile devices'
));

userStories.add(new User_Story__c(
    Name = 'Build sales metrics widget',
    Description__c = 'Create widget showing sales metrics: total revenue, deals closed, conversion rate. Include date range filter and trend indicators.',
    Status__c = 'Backlog',
    Priority__c = 'Medium',
    Feature__c = features[1].Id,
    Acceptance_Criteria__c = '1. Metrics update in real-time\n2. Date range filter works\n3. Trend arrows display correctly\n4. Data refreshes every 5 minutes'
));

userStories.add(new User_Story__c(
    Name = 'Add export functionality',
    Description__c = 'Implement export to CSV and PDF for dashboard data. Include options for date range, specific metrics, and formatting preferences.',
    Status__c = 'Backlog',
    Priority__c = 'Low',
    Feature__c = features[1].Id,
    Acceptance_Criteria__c = '1. CSV export includes all selected data\n2. PDF export formats correctly\n3. Export completes within 30 seconds\n4. Email option available for large exports'
));

// User Stories for "Mobile App Integration"
userStories.add(new User_Story__c(
    Name = 'Design REST API endpoints',
    Description__c = 'Design and document REST API endpoints for mobile app. Include authentication, rate limiting, versioning, and error handling specifications.',
    Status__c = 'Done',
    Priority__c = 'Critical',
    Feature__c = features[2].Id,
    Assignee__c = currentUser.Id,
    Acceptance_Criteria__c = '1. API documentation complete\n2. All endpoints follow RESTful conventions\n3. Rate limiting implemented\n4. Error responses standardized'
));

userStories.add(new User_Story__c(
    Name = 'Implement iOS SDK',
    Description__c = 'Build iOS SDK in Swift with authentication, data sync, and offline support. Include comprehensive documentation and sample app.',
    Status__c = 'In_Progress',
    Priority__c = 'High',
    Feature__c = features[2].Id,
    Assignee__c = currentUser.Id,
    Acceptance_Criteria__c = '1. SDK compiles without errors\n2. Authentication flow works\n3. Offline sync functions correctly\n4. Sample app demonstrates all features'
));

userStories.add(new User_Story__c(
    Name = 'Implement Android SDK',
    Description__c = 'Build Android SDK in Kotlin with authentication, data sync, and offline support. Include comprehensive documentation and sample app.',
    Status__c = 'Backlog',
    Priority__c = 'High',
    Feature__c = features[2].Id,
    Acceptance_Criteria__c = '1. SDK builds successfully\n2. Authentication flow works\n3. Offline sync functions correctly\n4. Sample app demonstrates all features'
));

userStories.add(new User_Story__c(
    Name = 'Add offline sync capabilities',
    Description__c = 'Implement offline data synchronization with conflict resolution. Support queue-based sync and background updates when connection restored.',
    Status__c = 'Blocked',
    Priority__c = 'Medium',
    Feature__c = features[2].Id,
    Acceptance_Criteria__c = '1. Data queues when offline\n2. Sync runs automatically when online\n3. Conflicts resolved per strategy\n4. Progress indicator displays during sync'
));

// User Stories for "Notification System"
userStories.add(new User_Story__c(
    Name = 'Create notification preferences page',
    Description__c = 'Build user interface for managing notification preferences. Users can enable/disable email, SMS, and in-app notifications by category.',
    Status__c = 'Done',
    Priority__c = 'Medium',
    Feature__c = features[3].Id,
    Assignee__c = currentUser.Id,
    Acceptance_Criteria__c = '1. All preference options display\n2. Changes save successfully\n3. Confirmation message appears\n4. Preferences persist across sessions'
));

userStories.add(new User_Story__c(
    Name = 'Implement email notification service',
    Description__c = 'Build email notification service with templates, personalization, and delivery tracking. Integrate with email service provider.',
    Status__c = 'Done',
    Priority__c = 'High',
    Feature__c = features[3].Id,
    Assignee__c = currentUser.Id,
    Acceptance_Criteria__c = '1. Emails sent within 5 minutes\n2. Templates render correctly\n3. Personalization works\n4. Delivery status tracked'
));

userStories.add(new User_Story__c(
    Name = 'Build notification history view',
    Description__c = 'Create page showing notification history with filters by type, date range, and status. Include mark as read/unread functionality.',
    Status__c = 'Done',
    Priority__c = 'Low',
    Feature__c = features[3].Id,
    Acceptance_Criteria__c = '1. All notifications display\n2. Filters work correctly\n3. Mark as read updates status\n4. Pagination handles large lists'
));

insert userStories;

System.debug('Created ' + userStories.size() + ' User Story records');

// Summary
System.debug('=== Test Data Creation Complete ===');
System.debug('Features created: ' + features.size());
System.debug('User Stories created: ' + userStories.size());
System.debug('Feature IDs:');
for (Feature__c f : features) {
    System.debug('  - ' + f.Name + ': ' + f.Id);
}





