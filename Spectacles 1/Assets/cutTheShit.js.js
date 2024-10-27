var SIK = require("SpectaclesInteractionKit/SIK").SIK;

// SIK.GestureManager.onSwipe().subscribe(function(gesture) {
//     const hitTest = Scene.root.hitTest(gesture.position);
    
//     if (hitTest && hitTest.object) {
//         const fruit = hitTest.object;
//         if (fruitObjects.includes(fruit)) {
//             sliceFruit(fruit);
//         }
//     }
// });

// function sliceFruit(fruit) {
//     SIK.Animations.play('sliceAnimation', fruit); // Play slicing animation
//     fruitObjects.splice(fruitObjects.indexOf(fruit), 1); // Remove from array
//     fruit.hidden = true; // Hide watermelon
//     score += 10;
//     updateScoreUI();
// }
