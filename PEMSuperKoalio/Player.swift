// Based on Ray Wenderlichs SpriteKit SuperKoalio game tutorial by Jake Gunderson.
// https://www.raywenderlich.com/2554-sprite-kit-tutorial-how-to-make-a-platform-game-like-super-mario-brothers-part-1

import SpriteKit
import CoreGraphics

class Player : SKSpriteNode {
    var desiredPosition = CGPoint.zero
    var velocity = CGPoint.zero
    var onGround = false
    var forwardMarch = false
    var mightAsWellJump = false

    class func newPlayer() -> Player {
        let texture = SKTexture(imageNamed: "koalio_stand")
        let newPlayer = Player(texture: texture, color: .clear, size: CGSize(width: 18, height: 26))

        return newPlayer
    }
    
    func update(_ delta: TimeInterval) {
        let gravity = CGPoint(x: 0, y: -450)
        let gravityStep = gravity.multiplyScalar(delta)
        
        //1
        let forwardMove = CGPoint(x: 800.0, y: 0.0)
        let forwardMoveStep = forwardMove.multiplyScalar(delta)
        velocity = velocity.add(gravityStep)
        
        //2
        velocity = CGPoint(x: velocity.x * 0.9, y: velocity.y)
        
        //3
        let jumpForce = CGPoint(x: 0.0, y: 310.0)
        let jumpCutoff = CGFloat(150.0)

        if mightAsWellJump && onGround {
            velocity = velocity.add(jumpForce)
            run(SKAction.playSoundFileNamed("jump.wav", waitForCompletion: true))
        } else if !mightAsWellJump && velocity.y > jumpCutoff {
            velocity = CGPoint(x: velocity.x, y: jumpCutoff)
        }
        
        if forwardMarch {
            velocity = velocity.add(forwardMoveStep)
        }
        
        //4
        let minMovement = CGPoint(x: 0.0, y: -450)
        let maxMovement = CGPoint(x: 120.0, y: 250.0)
        velocity = CGPoint(x: velocity.x.clamp(min: minMovement.x, max: maxMovement.x), y: velocity.y.clamp(min: minMovement.y, max: maxMovement.y));
        
        let velocityStep = velocity.multiplyScalar(delta)
        desiredPosition = position.add(velocityStep)
    }
    
    func collisionBoundingBox() -> CGRect {
        let boundingBox = frame.insetBy(dx: 2, dy: 0)
        let diff = desiredPosition.subtract(position);
        return boundingBox.offsetBy(dx: diff.x, dy: diff.y);
    }
}
