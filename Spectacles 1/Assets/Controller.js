var gameRunning = false;

function onAwake() {
    script.createEvent('OnStartEvent').bind(onStart);
}

function onStart() {
    // Initialize the game
    gameRunning = false;
}

function startGame() {
    if (!gameStarted) {
        gameRunning = true;
        print("Starting watermelon spawn!");
        global.fruitSpawnerScript.spawnWatermelons(); // Call the spawner when the game starts
    }
}

onAwake();
