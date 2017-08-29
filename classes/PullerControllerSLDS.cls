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