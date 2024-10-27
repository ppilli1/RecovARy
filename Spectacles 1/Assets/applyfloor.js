// @input Physics.BodyComponent physicsBox
// @input SceneObject surfaceTracking

function onSurfaceDetected(eventData) {
    var surfaceTransform = eventData.transform;
    script.physicsBox.getTransform().setWorldPosition(surfaceTransform.getWorldPosition());
    script.physicsBox.getTransform().setWorldRotation(surfaceTransform.getWorldRotation());
    script.physicsBox.getTransform().setLocalScale(surfaceTransform.getLocalScale());
}

script.surfaceTracking.onSurfaceDetected.add(onSurfaceDetected);