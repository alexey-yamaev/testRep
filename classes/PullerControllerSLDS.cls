/**
 * Created by User on 28.08.2017.
 */

public class PullerControllerSLDS {

    private static Map <String, Schema.SObjectType> schemaMap = Schema.getGlobalDescribe();
    public static List<String> objectNames = new List<String>();
    public static List<Pair> fieldList = new List<Pair>();
    public static List<Condition> conditions = new List<Condition>();

    @RemoteAction
    public static List<String> getObjectNames() {
    initObjNames();
        return objectNames;
    }

    @RemoteAction
    public static List<Pair> getFieldList(String selectedName) {
        Map <String, Schema.SObjectField> fieldMap = schemaMap.get(selectedName).getDescribe().fields.getMap();
        List<String> fields = new List<String>(fieldMap.keySet());
        fields.sort();

        for (String name : fields) {
            Pair field = new Pair();
            field.name = name;
            field.selected = false;
            fieldList.add(field);
        }
        return fieldList;
    }

    @RemoteAction
    public static String constructQuery(List<Pair> fieldList, String selectedObject, List<Condition> conditions) {
        String query = 'SELECT';
        Integer fieldCount = 0;
        for (Pair p : fieldList) {
            if (p.selected) {
                query += (fieldCount++ > 0) ? ',' : '' ;
                query += ' ' + p.name;
            }
        }

        query += ' FROM ' + selectedObject;
        if (fieldCount == 0) {
            query = 'Choose fields to select from database';
            return query;
        }

        Boolean firstCondition = true;
        if (!conditions.isEmpty()) {

            String andCondition = '';
            String orCondition = '';

            for (Condition c : conditions) {
                if (c.andOrSelected == 'AND' && !String.isEmpty(c.value) && c.field != null) {
                    andCondition += 'AND ' + c.field + ' ' + c.operatorSelected;
                    if (c.operatorSelected == 'LIKE') {
                        andCondition += ' \'%' + c.value + '%\' ';
                    } else {
                        andCondition += ' \'' + c.value + '\' ';
                    }
                } else if (c.andOrSelected == 'OR' && !String.isEmpty(c.value) && c.field != null) {
                    orCondition += 'OR ' + c.field + ' ' + c.operatorSelected;
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
        return query;
    }

    @RemoteAction
    public static String queryDB(List<Pair> fieldList, String selectedObject, List<Condition> conditions) {
        String query = constructQuery(fieldList, selectedObject, conditions);
        String queryResultStr;
        if (!query.contains('Choose fields to select from database') && !fieldList.isEmpty()) {
            List<sObject> selectResult = new List<sObject>();
            system.debug('fieldList ' + fieldList);
            system.debug('query' + query);
            try {
                selectResult = Database.query(query);
            }
            catch (Exception e) {
                return e.getMessage();
            }


            if (selectResult.size() != 0) {
                queryResultStr = '';
                for (Integer i=0; i < selectResult.size(); i++) {
                    queryResultStr += selectResult.get(i) + '\n';
                }
            } else {
                queryResultStr = 'No records were found';
            }
        }
        else {
            queryResultStr = 'No fields are selected';
        }
        return queryResultStr;
    }

    @RemoteAction
    public static List<Condition> addCondition(List<Condition> conditions) {
        conditions.add(new Condition());
        return conditions;
    }

    @RemoteAction
    public static List<Condition> removeCondition(List<Condition> conditions, Integer index) {
        if (!conditions.isEmpty()) {
            conditions.remove(index);
        }
        return conditions;
    }

    @RemoteAction
    public static List<Condition> getConditions() {
        return conditions;
    }

    private static void initObjNames() {
        List<String> entities = new List<String>(schemaMap.keySet());
        entities.sort();
        for(String name : entities) {
                objectNames.add(name);
        }
    }

    private class Pair  {
        public String name { get; set; }
        public Boolean selected { get; set; }
    }

    private class Condition {
        public String value { get; set; }
        public String andOrSelected { get; set; }
        public String operatorSelected { get; set; }
        public String field { get; set; }
    }
}