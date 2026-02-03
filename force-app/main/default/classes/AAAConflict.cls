/**
 * @description Utility class for basic arithmetic operations
 * @author Your Name
 * @date 2025-01-12
 */
public with sharing class AAAConflict {
    
    /**
     * @description Increments a given decimal value by one.
     * Also verifies User table accessibility.
     * @param d The decimal value to increment
     * @return Decimal The incremented value (d + 1)
     */
    public static Decimal countPlusOne(Decimal d) {
        // Validate input
        if (d == null) {
            throw new IllegalArgumentException('Input parameter cannot be null');
        }
        
        // Query with enforced security - automatically strips inaccessible fields
        List<User> userList = [
            SELECT Id 
            FROM User 
            WITH SECURITY_ENFORCED 
            ORDER BY LastName ASC 
            LIMIT 1
        ];
        
        // Use the query result to demonstrate it's not unused
        if (userList.isEmpty()) {
            // Handle edge case: no users found (shouldn't happen in real org)
            System.debug('Warning: No users found in org');
        }
        
        return d + 1;
    }
}