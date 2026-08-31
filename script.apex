List<Folder> folders = [SELECT Id, Name, DeveloperName FROM Folder WHERE Type = 'Email' ORDER BY Name ASC];
for(Folder f : folders) {
    System.debug('FOLDER: ' + f.Name);
    List<EmailTemplate> templates = [SELECT Name, DeveloperName FROM EmailTemplate WHERE FolderId = :f.Id ORDER BY Name ASC];
    if(templates.isEmpty()) {
        System.debug('  - (Vacía)');
    } else {
        for(EmailTemplate et : templates) {
            System.debug('  - ' + et.Name);
        }
    }
}
