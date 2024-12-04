/*
@author Arif Mahmud, Trainee Salesforce Engineer BJIT
Details : Batch class for update the tasks checks task status whether they are overdue or not
Date : 25-11-2020

1. Task Status Update:
    -For each Task__c record:
    ▪ If the Due_Date__c field is past today and the Task_Status__c is not
        Completed, update the Task_Status__c to Overdue.
2. Project Cost Calculation:
    -For each Project__c, calculate the total cost of related tasks (Task_Cost__c) and
    update the Total_Cost__c field on the Project__c.
3. Send Notification:
    -After processing, send an email to the system administrator summarizing:
        ▪ The total number of tasks processed.
        ▪ The number of tasks marked as Overdue.
        ▪ The total cost updated for all projects.


*/

global class BatchExample implements Database.Batchable<SObject> {
    global Database.QueryLocator start(Database.BatchableContext bc) {
        // Collecting the batches of records or objects to be passed to execute
        return Database.getQueryLocator('SELECT Id, Name, Due_Date__c, Task_Cost__c, Task_Status__c, Project__c FROM Task__c');
        
    }
    private Integer totalTasksProcessed = 0; 
    private Integer tasksMarkedOverdue = 0; 
    private Decimal totalCostUpdated = 0;

    global void execute(Database.BatchableContext bc, List<SObject> scope) {
        // Process each batch of records
        
        List<Task__c> tasksToUpdate = new List<Task__c>();


        for(Task__c task: (List<Task__c>)scope){
            if(task.Due_Date__c < Date.today() && task.Task_Status__c != 'Completed'){
                task.Task_Status__c = 'Overdue';
                tasksToUpdate.add(task);
            }
        }
        UPDATE scope;

        // Fetch the related projects 
        Set<Id> projectIds = new Set<Id>(); 
        for (Task__c task : (List<Task__c>)scope) { 
            projectIds.add(task.Project__c); 
        } 

        List<Project__c> updateProjectList = [
            SELECT Id, (SELECT Task_Cost__c FROM Tasks__r) 
            FROM Project__c 
            WHERE 
            Id IN :projectIds
        ]; 
        
        // Update total SUM of task cost to project cost__c field 
        for (Project__c project : updateProjectList) { 
            project.Total_Cost__c = 0; 
            for (Task__c task : project.Tasks__r) { 
                if (task.Task_Cost__c != null) { 
                    project.Total_Cost__c += task.Task_Cost__c; 
                } 
            } 
        } 
        update updateProjectList;
        

        totalTasksProcessed += scope.size(); 
        tasksMarkedOverdue += tasksToUpdate.size(); 
         
        for (Project__c project : updateProjectList) { 
            totalCostUpdated += project.Total_Cost__c; 
        }


        // formating email body
        String emailBody = 'Task Processing Summary: \n' + 'Total tasks processed: ' + totalTasksProcessed + '\n' + 'Tasks marked as Overdue: ' + tasksMarkedOverdue + '\n' + 'Total cost updated for all projects: ' + totalCostUpdated;


        // Defining the email
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        String[] toAddresses = new String[] { 'smarifmahmud9@gmail.com' }; // Change to the recipient's email address

        mail.setToAddresses(toAddresses);
        mail.setSubject('Adminstrator Batch Processing Change Alert');
        mail.setPlainTextBody('Dear Adminstartor,'+'\nHere are the Statistics \n' +emailBody + '\nRegards\nArif\nBJIT ACADEMY');

        // Send the email
        Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
    }

    global void finish(Database.BatchableContext bc) {
        // Executes any post-processing operations
        System.debug('Batch execution finished.');
    }
}
