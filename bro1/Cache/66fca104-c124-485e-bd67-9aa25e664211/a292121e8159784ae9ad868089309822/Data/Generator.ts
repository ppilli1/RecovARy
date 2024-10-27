@component
export class NewScript extends BaseScriptComponent {

    @input
    ball: ObjectPrefab
    
    generate(){
        let newBall = this.ball.instantiate(this.getSceneObject())
    }
}
