//@input Asset.ObjectPrefab watermelonPrefabs
//@input vec2 randomBounds
//@input SceneObject camera
//@input Asset.RemoteServiceModule remoteServiceModule

var times = [];
function spawnWatermelons() {
    // script.createEvent('OnStartEvent').bind(onStart);

    if (times.length >= 7){
        const bb = times.toString();

        const raw = JSON.stringify({
            "scores_text": bb,
            "game": "FN"
        })
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
    
    var r = Math.floor(Math.random() * script.watermelonPrefabs.length)
    var spawnedObject = script.watermelonPrefabs.instantiate(null);

    var randomOffset = new vec3(((Math.random() - 0.5) * script.randomBounds.x), 200, ((Math.random() - 0.5) * script.randomBounds.x));

    var camT = script.camera.getTransform();
//    var newPos = camT.getWorldPosition().add(camT.forward.uniformScale(100 + Math.random() * 30)).add(camT.right.uniformScale(Math.random() - 0.5) * script.randomBounds.x);
//    newPos.y = 65;
    var newPos = camT.getWorldPosition().add(camT.forward.uniformScale(-150)).add(camT.right.uniformScale(Math.floor(Math.random() * 40 ) - 20));
    newPos.y = 150;
    spawnedObject.getTransform().setWorldPosition(newPos);
    
}

global.spawnnewwatermelon = function(names) {
    spawnWatermelons();
    if (names !== 'groundPlane'){
        times.push(getTime());
    };
    
    print(times);
}

script.ongroundfound = function() {
    print("Kickoff spawning");
    spawnnewwatermelon();
    
};