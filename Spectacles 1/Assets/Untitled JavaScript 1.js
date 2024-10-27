//@input Physics.BodyComponent body

script.body.onCollisionEnter.add(function(eventArgs) {
    var collision = eventArgs.collision;
    print("CollisionEnter(" + collision.id + "): contacts=" + collision.contactCount + " ---> " + collision.collider.getSceneObject().name);
    print("about to spawn");
    var names = collision.collider.getSceneObject().name;
    global.spawnnewwatermelon(names);
    script.getSceneObject().destroy();

    
});