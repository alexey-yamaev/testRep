public class PullerController
{
    public Map <String, Schema.SObjectType> schemaMap = Schema.getGlobalDescribe();
    public List <Pair> lstfieldname{ get; set; }
    public List <Pair> fields { 
        get {
        	return lstfieldname; 
    	} 
        set { 
            lstfieldname=value; 
        } 
    }
    public List <SelectOption> objectNames{ public get; private set; }
    public String selectedObject { get; set; }
    public String query { get; set; }
    public String selectResult { get; set; }
    public Integer fieldCount { get; set; }
    public List <SelectOption> andOrList { public get; private set; }
    public List <SelectOption> operatorsList { public get; private set; }
    public List <Condition> conditions { public get; private set; }
    public List <SelectOption> fieldNames { public get; private set; }
    private final String AND_STR = 'AND';
    private final String OR_STR = 'OR';    
    
    public PullerController() {        
        conditions = new List<Condition>();
		initObjNames();
        fields = new List<Pair>();
        resetFileds();
    }
    
    private void initObjNames() {
        andOrList = new List<SelectOption>();
		andOrList.add(new SelectOption(AND_STR, AND_STR));
        andOrList.add(new SelectOption(OR_STR, OR_STR));
        
        operatorsList = new List<SelectOption>();
        operatorsList.add(new SelectOption('=', '='));
        operatorsList.add(new SelectOption('!=', '!='));
        operatorsList.add(new SelectOption('LIKE', 'LIKE'));
        
        objectNames = new List<SelectOption>();
        List<String> entities = new List<String>(schemaMap.keySet());
        entities.sort();
        objectNames.add(new SelectOption('-', '-'));
        for(String name : entities)
        	objectNames.add(new SelectOption(name,name));
    }
    
    public void showFields()  {
        resetFileds();
        if (selectedObject == '-')
            return;
        Map <String, Schema.SObjectField> fieldMap = schemaMap.get(selectedObject).getDescribe().fields.getMap();
        List<String> fields = new List<String>(fieldMap.keySet());
        fields.sort();
        fieldNames =  new List<SelectOption>();
        
        for (String name : fields) {
            Pair field = new Pair();
            field.name = name;
            field.selected = false;
            lstfieldname.add(field);
            fieldNames.add(new SelectOption(name, name));
        }
    }
    
    public void constructQuery() {
        query = 'SELECT';
        fieldCount = 0;
        for (Pair p : lstfieldname) {
            if (p.selected) {
                query += (fieldCount++ > 0) ? ',' : '' ;
                query += ' ' + p.name;                
            }
        }
        
        query += ' FROM ' + selectedObject;        
        if (fieldCount == 0) {
            query = 'Choose fields to select from database';
            return;
        }            
        
        Boolean firstCondition = true;
        if (!conditions.isEmpty()) {
            
            String andCondition = '';
            String orCondition = '';

            for (Condition c : conditions) {                
                if (c.andOrSelected == AND_STR && !String.isEmpty(c.value)) {
                    andCondition += AND_STR + ' ' + c.fieldSelected + ' ' + c.operatorSelected;
                    if (c.operatorSelected == 'LIKE') {
                        andCondition += ' \'%' + c.value + '%\' ';
                    } else {
                        andCondition += ' \'' + c.value + '\' ';
                    }                    
                } else if (c.andOrSelected == OR_STR && !String.isEmpty(c.value)) {
                    orCondition += OR_STR + ' ' + c.fieldSelected + ' ' + c.operatorSelected;
                    if (c.operatorSelected == 'LIKE') {
                        orCondition += ' \'%' + c.value + '%\' ';
                    } else {
                        orCondition += ' \'' + c.value + '\' ';
                    }
                }
        	}
            
            if (!String.isEmpty(andCondition)) {
                query += ' WHERE ';
                andCondition = andCondition.substring(4);
                query += '( ' + andCondition + ' ) ';
                query += orCondition;
            } 
            else if (String.isEmpty(andCondition) && !String.isEmpty(orCondition)) {
                query += ' WHERE ';
                orCondition = orCondition.substring(3);
                query += orCondition;
            }
        }
    }

    public void queryDB() {
        constructQuery();
        if (fieldCount != 0) {                
            List<sObject> resultList = new List<sObject>();
            system.debug('QUERY ' + query);
            
            try {
                resultList = Database.query(query);
            }
            catch (Exception e) {             
            	ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.ERROR, e.getMessage());
            	ApexPages.addMessage(myMsg);
                return;
            }
            
            if (resultList.size() != 0) {
                selectResult = '';
                for (Integer i=0; i < resultList.size(); i++) {
                    selectResult += resultList.get(i) + '<br/>';
                }
            } else {
                selectResult = 'No records were found';
            }
        }
        else {
        	query = 'No fields are selected'; 
            selectResult = null;
        }
    }

    public void addCondition() {
        conditions.add(new Condition());
    }
    
    public void removeCondition() {
        if (!conditions.isEmpty())
        	conditions.remove(conditions.size() - 1);
    }
    
    private void resetFileds()
    {
        fields.clear();
        conditions.clear();
        query = 'Choose fields to select from database';
        selectResult = '';
        fieldCount = 0;
    }

    private class Pair  {
        public String name { get; set; }
        public Boolean selected { get; set; }
    }
    
    private class Condition {
        public String value { get; set; }
        public String andOrSelected { get; set; }
        public String operatorSelected { get; set; }
        public String fieldSelected { get; set; }
    }
}