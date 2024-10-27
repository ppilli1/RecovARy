// const SIK = require('SpectaclesInteractionKit/SIK').SIK;
// const interactionManager = SIK.InteractionManager;
// const interactionConfiguration = SIK.InteractionConfiguration;
// // const Time = require('Time');

// let gameStarted = false; // Track if the game has started
// let fruitObjects = [];
// let fallSpeed = 0.002; // Adjust fall speed 

// function onAwake() {
//   // Wait for other components to initialize
//   script.createEvent('OnStartEvent').bind(() => {
//     onStart();
//   });
// }

// function onStart() {
//   // Initialize the Interactable component for sword interaction
//   // const interactableTypename = interactionConfiguration.requireType('Interactable');
//   // let interactable = script.sceneObject.getComponent(interactableTypename);
//   // // Retrieve interactable for sword
//   // interactable = interactionManager.getInteractableBySceneObject(script.sceneObject);
//   // print(interactable);

//   // // Define the interaction logic for when the sword touches another object
//   // const onTriggerStartCallback = (event) => {
//   //   print(
//   //     `Sword interaction detected! Input type: ${event.interactor.inputType} at position: ${event.interactor.targetHitInfo.hit.position}`
//   //   );

//     // Start the game if it hasn't started yet
//     // if (!gameStarted) {
//       startGame();
//       gameStarted = true; // Prevent the game from starting multiple times
//     // }
//   // };

//   // interactable.onInteractorTriggerStart(onTriggerStartCallback);
// }

// // Function to start the game (spawn watermelons)
// function startGame() {
//   print('Game Started! Watermelons are falling!');

//   // Use SIK's ObjectPool to spawn watermelons
//   SIK.ObjectPool.init({
//     objectTemplate: 'Watermelon', // Your 3D watermelon asset name
//     poolSize: 10
//   }).then(pool => {
//     // Create watermelons with random spawn positions and falling behavior
//     for (let i = 0; i < 10; i++) {
//       createWatermelon(pool);
//     }

//     // Start falling effect
//     Time.setInterval(updateWatermelons, 30); // Update every 30ms (~33fps)
//   });
// }

// // Function to create watermelon at a random position
// function createWatermelon(pool) {
//   const watermelon = pool.spawn();

//   // Set random x position for each watermelon
//   watermelon.transform.x = Math.random() * 0.5 - 0.25; // Random x between -0.25 and 0.25
//   watermelon.transform.y = 0.5; // Start at the top of the screen
//   watermelon.transform.z = -0.5; // Depth position

//   fruitObjects.push(watermelon); // Add watermelon to the array
// }

// // Function to update the position of all watermelons to simulate falling
// function updateWatermelons() {
//   fruitObjects.forEach(watermelon => {
//     watermelon.transform.y -= fallSpeed; // Move watermelon down the screen

//     // Reset position if the watermelon goes off the bottom of the screen
//     if (watermelon.transform.y < -0.5) {
//       resetWatermelonPosition(watermelon);
//     }
//   });
// }

// // Function to reset watermelon position (for continuous fall)
// function resetWatermelonPosition(watermelon) {
//   watermelon.transform.x = Math.random() * 0.5 - 0.25; // New random x position
//   watermelon.transform.y = 0.5; // Reset to top of the screen
// }

// onAwake();
