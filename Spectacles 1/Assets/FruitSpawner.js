//@input Asset.ObjectPrefab[] watermelonPrefabs
//@input SceneObject spawnParent
//@input vec2 randomBounds
//@input SceneObject camera
// FruitSpawner.js
// const SIK = require('SpectaclesInteractionKit/SIK').SIK;

// var plane = script.getSceneObjectByName('Plane'); // Plane should be the object at the top
// var watermelonPrefab = script.watermelonPrefab; // Watermelon

// Set spawn interval (seconds)
var spawnInterval = 2.0;
var watermelonSpeed = 2.0; // Speed of falling

var datatosendspawntimes = [];
global.isgamerunning = true;




global.spawnnewwatermelon = function() {
    spawnWatermelons();
    times.push(getTime());
    print(times);
}

function spawnWatermelons() {
    // script.createEvent('OnStartEvent').bind(onStart);

    if (times.length >= 20){
        print("fetched")
    }
    
    var r = Math.floor(Math.random() * script.watermelonPrefabs.length)
    var spawnedObject = script.watermelonPrefabs[r].instantiate(null);

    var randomOffset = new vec3(((Math.random() - 0.5) * script.randomBounds.x), 200, ((Math.random() - 0.5) * script.randomBounds.x));

    var camT = script.camera.getTransform();
//    var newPos = camT.getWorldPosition().add(camT.forward.uniformScale(100 + Math.random() * 30)).add(camT.right.uniformScale(Math.random() - 0.5) * script.randomBounds.x);
//    newPos.y = 65;
    var newPos = camT.getWorldPosition().add(camT.forward.uniformScale(-100)).add(camT.right.uniformScale(Math.random() * script.randomBounds.x));
    newPos.y = 250;
    spawnedObject.getTransform().setWorldPosition(newPos);
    
}

script.spawn = spawnnewwatermelon;

function onStart() {
    if (isgamerunning === true){
        script.createEvent('UpdateEvent').bind(update);
        spawnnewwatermelon();
    }
    
}


function delayedCallback(delay, callback) {
    var event = script.createEvent("DelayedCallbackEvent");
    event.bind(callback);
    event.reset(delay);
    return event;
}
if (isgamerunning === true){
    delayedCallback(1, spawnnewwatermelon);
}



// spawnWatermelons();
