public class RoleTreeController {
    public class RoleNode {
        public String id { get; set; }
        public String text { get; set; }
        public List<RoleNode> children { get; set; }

        public RoleNode(UserRole r) {
            id = r.Id;
            text = r.Name;
            children = new List<RoleNode>();
        }
    }

    public String roleTreeJson { get; set; }

    public RoleTreeController() {
        List<RoleNode> roleTree = buildRoleTree();
        roleTreeJson = JSON.serialize(roleTree);
    }

    public List<RoleNode> buildRoleTree() {
        List<RoleNode> roleTree = new List<RoleNode>();
        Map<Id, RoleNode> roleMap = new Map<Id, RoleNode>();

        // Query all roles
        UserRole[] allRoles = [SELECT Id, Name, ParentRoleId FROM UserRole ORDER BY Name];

        // Create RoleNode instances and populate roleMap
        for (UserRole r : allRoles) {
            RoleNode node = new RoleNode(r);
            roleMap.put(r.Id, node);
        }

        // Build the role tree hierarchy
        for (UserRole r : allRoles) {
            RoleNode node = roleMap.get(r.Id);
            if (r.ParentRoleId != null && roleMap.containsKey(r.ParentRoleId)) {
                RoleNode parent = roleMap.get(r.ParentRoleId);
                parent.children.add(node);
            } else {
                roleTree.add(node); // Add as root if no parent or parent not found
            }
        }

        return roleTree;
    }
}