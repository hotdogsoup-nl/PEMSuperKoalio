import SpriteKit
import CoreGraphics

let SpawnTypePlayer = "Player"

enum MovementDirection {
    case idle
    case left
    case right
}

class Player : SKSpriteNode {
    var isDead = false
    var onGround = false
    var shouldJump = false
    var direction = MovementDirection.idle
    var desiredPosition = CGPoint.zero
    var velocity = CGPoint.zero

    private let jumpForce = CGPoint(x: 0, y: gameTileSize.height * 15)
    private let movementForce = CGFloat(playerSize.width * 10)
    private let movementDecelerationFactor = CGFloat(0.9)

    class func newPlayer() -> Player {
        let newPlayer = Player(color: .clear, size: playerSize)
        newPlayer.texture = SKTexture(imageNamed: "koalio_stand")

        return newPlayer
    }
    
    func update(_ delta: TimeInterval) {
        let gravityStep = gravity.multiplyScalar(delta)
        velocity = velocity.add(gravityStep)
        
        if isDead {
            velocity = CGPoint(x: velocity.x * movementDecelerationFactor, y: velocity.y)
        }

        if shouldJump && onGround {
            if !isDead {
                velocity = velocity.add(jumpForce)
                onGround = false
            } else {
                velocity = CGPoint(x: velocity.x, y: 0)
            }
        }
                
        if !isDead {
            switch direction {
            case .idle:
                velocity = CGPoint(x: 0, y: velocity.y)
                break
            case .left:
                velocity = CGPoint(x: -movementForce, y: velocity.y)
                xScale = -1.0
                break
            case .right:
                velocity = CGPoint(x: movementForce, y: velocity.y)
                xScale = 1.0
                break
            }
        }
        
        let velocityStep = velocity.multiplyScalar(delta)
        desiredPosition = position.add(velocityStep)
    }
    
    func collisionBoundingBox() -> CGRect {
        let offset = CGPoint(x: 2.0, y: 2.0)
        let clippingHeight = gameTileSize.height - size.height
        let boundingBox = CGRect(x: frame.origin.x + offset.x * 0.5, y: frame.origin.y - clippingHeight * 0.25 - offset.y, width: size.width - offset.x, height: size.height + clippingHeight)
        let diff = desiredPosition.subtract(position);
        return boundingBox.offsetBy(dx: diff.x, dy: diff.y);
    }
    
}
