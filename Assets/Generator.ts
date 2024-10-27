@component
export class NewScript extends BaseScriptComponent {
    
    @input
    ball: ObjectPrefab
    onAwake() {

    }
    
    generate(){
        let newBall = this.ball.instantiate(this.getSceneObject())
    }
}
