List<Folder> folders = [SELECT Id, Name FROM Folder WHERE Type = 'Email' AND Name LIKE 'Pyatz%'];
for(Folder f : folders) {
    System.debug('FOLDER: ' + f.Name);
    List<EmailTemplate> templates = [SELECT Name, HtmlValue, Body FROM EmailTemplate WHERE FolderId = :f.Id];
    for(EmailTemplate et : templates) {
        String content = et.HtmlValue != null ? et.HtmlValue : (et.Body != null ? et.Body : '');
        
        // Find merge fields like {!Object.Field} or {{{Object.Field}}}
        Matcher m1 = Pattern.compile('\\{!([^}]+)\\}').matcher(content);
        List<String> fields = new List<String>();
        while(m1.find()) { fields.add(m1.group(1)); }
        
        Matcher m2 = Pattern.compile('\\{\\{\\{([^}]+)\\}\\}\\}').matcher(content);
        while(m2.find()) { fields.add(m2.group(1)); }
        
        if(!fields.isEmpty()) {
            System.debug('  - Template: ' + et.Name + ' | Merge Fields: ' + String.join(fields, ', '));
        } else {
            System.debug('  - Template: ' + et.Name + ' | (Sin campos dinámicos)');
        }
    }
}
