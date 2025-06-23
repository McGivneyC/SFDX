public with sharing class AAAConflict{ 
 public static Decimal countPlusOne(Decimal d){ 
 /** I am a CONFLICT 6/23/25 **/ 
 for(Integer i = 0; i<10; i++){ 
 List<User> myList = [SELECT Id FROM User WITH SECURITY_ENFORCED ORDER BY LastName ASC LIMIT 1]; 
 } 
 return d+1; 
 } 
}