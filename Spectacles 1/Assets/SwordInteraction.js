// SwordInteraction.js
const SIK = require('SpectaclesInteractionKit/SIK').SIK;

var sword = script.getSceneObjectByName('Sword'); // Sword should be named correctly
var gameStarted = false;

function onAwake() {
    script.createEvent('OnStartEvent').bind(onStart);
}

function onStart() {
    var swordInteractable = sword.getComponent("Interactable");
    
    if (swordInteractable) {
        swordInteractable.onInteractorTriggerStart(function(event) {
            if (!gameStarted) {
                gameStarted = true;
                print("Game has started!");
                global.controllerScript.startGame();  // Make sure the controller script has this function
            }
        });
    }
}

onAwake();
