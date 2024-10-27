//@input Physics.BodyComponent body
//@input Asset.RemoteServiceModule remoteServiceModule
/** @type {RemoteServiceModule} */

const speedData = [42, 47, 53, 48, 45, 55, 51, 54, 46, 47, 50, 41];

const bb = speedData.toString();

const raw = JSON.stringify({
    "scores_text": bb,
    "game": "TT"
})
// Call the function to send data


script.body.onCollisionEnter.add(function(eventArgs) {
    var collision = eventArgs.collision;
    print("CollisionEnter(" + collision.id + "): contacts=" + collision.contactCount + " ---> " + collision.collider.getSceneObject().name);
    if(collision.collider.getSceneObject().name === "C_Labtable_GEO"){
        var remoteServiceModule = script.remoteServiceModule;

        var httpRequest = RemoteServiceHttpRequest.create();
        httpRequest.url = 'https://x8ki-letl-twmt.n7.xano.io/api:k_DP2pKT/patient_scores';
        httpRequest.method = RemoteServiceHttpRequest.HttpRequestMethod.Post;
        httpRequest.setHeader('Content-Type', 'application/json');
        httpRequest.body = raw;
        
        print('Sending request!');
        
        remoteServiceModule.performHttpRequest(httpRequest, function (response) {
          print('Request response received');
          print('Status code: ' + response.statusCode);
          print('Content type: ' + response.contentType);
          print('Body: ' + response.body);
          print('Headers: ' + response.headers);
        });
    }

    

    
});