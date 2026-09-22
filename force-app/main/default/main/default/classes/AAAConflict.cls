public class AAAConflict{ 
 public static Decimal countPlusOne(Decimal d){ 
 /** I am a comment 09/21/26**/ 
 for(Integer i = 0; i<10; i++){ 
 List<User> myList = [SELECT Id FROM User ORDER BY LastName ASC LIMIT 1]; 
 } 
 return d+1; 
 } 
}