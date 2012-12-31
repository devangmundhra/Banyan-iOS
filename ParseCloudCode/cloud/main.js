// Use Parse.Cloud.define to define as many cloud functions as you want.
// For example:
Parse.Cloud.define("hello", function(request, response) {
  response.success("Hello world!");
});
 
// Function to get the list of users on Banyan who are also facebook friends
Parse.Cloud.define("facebookFriendsOnBanyan", function(request, response) {
    // Get the list of facebook friends
    var facebookFriendsId = request.params.facebookFriendsId;
     
    // Search the users that have one of these ids
    var query = new Parse.Query(Parse.User);
    query.containedIn("facebookId", facebookFriendsId);
    query.find({
        success: function(results) {
            // Got the users. Return these
            response.success(results);
        },
        error: function(error) {
            resonse.error(error);
        }
    });
});
