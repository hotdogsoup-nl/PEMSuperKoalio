// Based on Ray Wenderlichs SpriteKit SuperKoalio game tutorial by Jake Gunderson.
// https://www.raywenderlich.com/2554-sprite-kit-tutorial-how-to-make-a-platform-game-like-super-mario-brothers-part-1

import SpriteKit
import PEMTileMap

let LayerNameScreenLayout = "ScreenLayout"
let LayerNameTerrain = "Terrain"
let LayerNameSpawn = "Spawn"

class GameScene: SKScene, SKPhysicsContactDelegate {
    private enum TileQueryPosition: Int {
        case atCenter
        case above
        case aboveLeft
        case aboveRight
        case below
        case belowLeft
        case belowRight
        case toTheLeft
        case toTheRight
    }
    
    private var map: PEMTileMap?
    private var cameraNode: SKCameraNode

    private var player: Player?
    private var previousUpdateTime = TimeInterval(0)
    private var walls: PEMTileLayer?
    private var hazards: PEMTileLayer?
    
    // MARK: - Init
    
    override init(size: CGSize) {
        cameraNode = SKCameraNode()
        super.init(size: size)
        
        startControl()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Control

    private func startControl() {
        physicsWorld.contactDelegate = self
        camera = cameraNode
        addChild(cameraNode)
        
        loadMap()
    }
    
    private func loadMap() {
        if let newMap = PEMTileMap(mapName: "superkoalio.tmx") {
            map = newMap

            if newMap.backgroundColor != nil {
                backgroundColor = newMap.backgroundColor!
            } else {
                backgroundColor = .clear
            }

            cameraNode.zPosition = newMap.highestZPosition + 1
            newMap.cameraNode = cameraNode
            newMap.position = CGPoint(x: newMap.mapSizeInPoints().width * -0.5, y: newMap.mapSizeInPoints().height * -0.5)
            
            addChild(newMap)
            newMap.moveCamera(sceneSize: size, zoomMode: .aspectFill, viewMode: .bottomLeft)
            
            walls = newMap.layerNamed("walls") as? PEMTileLayer
            hazards = newMap.layerNamed("hazards") as? PEMTileLayer
            
            player = Player.newPlayer()
            player?.position = CGPoint(x: 100, y: 50)
            player?.zPosition = newMap.highestZPosition + 1
            newMap.addChild(player!)
        }
    }
        
    // MARK: - Game cycle
        
    override open func update(_ currentTime: TimeInterval) {
        super.update(currentTime)

        var delta = currentTime - previousUpdateTime

        if (delta > 0.02) {
            delta = 0.02;
        }

        self.previousUpdateTime = currentTime;
        
        player?.update(delta)
        checkForCollisionsAndMovePlayer()
    }
    
    // MARK: - Collision detection
    
    private func checkForCollisionsAndMovePlayer() {
        guard player != nil else { return }
        
        let tileQueryPositions : [TileQueryPosition] = [.below, .above, .toTheLeft, .toTheRight, .aboveLeft, .aboveRight, .belowLeft, .belowRight]
        player?.onGround = false
        
        for tileQueryPosition in tileQueryPositions {
            let playerRect = player?.collisionBoundingBox()
            let playerPosition = player!.desiredPosition.subtract(CGPoint(x: 0, y: player!.size.height * 0.5))
            let playerCoord = map!.tileCoords(positionInPoints: playerPosition)

            if playerCoord.y > map!.mapSizeInPoints().height {
                playerDiedSequence()
                return
            }

            let tileColumn = tileQueryPosition.rawValue % 3
            let tileRow = tileQueryPosition.rawValue / 3
            let tileCoord = CGPoint(x: Int(playerCoord.x) + tileColumn - 1, y: Int(playerCoord.y) + tileRow - 1)
            
            if let tileFound = map!.tileAt(tileCoords: tileCoord, inLayer: walls!) {
                let tileRect = tileFound.frame

                //1
                if playerRect!.intersects(tileRect) {
                    let intersection = playerRect!.intersection(tileRect)

                    //2
                    switch (tileQueryPosition) {
                    case .below:
                        player?.desiredPosition = CGPoint(x: player!.desiredPosition.x, y: player!.desiredPosition.y + intersection.size.height)
                        player!.velocity = CGPoint(x: player!.velocity.x, y: 0.0)
                        player?.onGround = true
                    case .above:
                        player!.desiredPosition = CGPoint(x: player!.desiredPosition.x, y: player!.desiredPosition.y - intersection.size.height)
                        break
                    case .toTheLeft:
                        player!.desiredPosition = CGPoint(x: player!.desiredPosition.x + intersection.size.width, y: player!.desiredPosition.y)
                        break
                    case .toTheRight:
                        player!.desiredPosition = CGPoint(x: player!.desiredPosition.x - intersection.size.width, y: player!.desiredPosition.y)
                        break
                    case .aboveLeft:
                        break
                    case .aboveRight:
                        break
                    case .atCenter:
                        break
                    case .belowLeft:
                        break
                    case .belowRight:
                        break
                    }
                    
                }
            }
        }
        
        //6
        player?.position = player!.desiredPosition
    }
    
    // MARK: - Game sequence
    
    private func levelCompletedSequence() {
    }
    
    private func playerDiedSequence() {
    }
    
    }

    // MARK: - Input handling

    private func touchDownAtPoint(_ pos: CGPoint) {
    }

    private func touchMovedToPoint(_ pos: CGPoint) {
    }

    private func touchUpAtPoint(_ pos: CGPoint) {
    }
}

#if os(iOS) || os(tvOS)
extension GameScene {
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        for t in touches {
            touchDownAtPoint(t.location(in: self))
        }
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        for t in touches {
            touchMovedToPoint(t.location(in: self))
        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        for t in touches {
            touchUpAtPoint(t.location(in: self))
        }
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        for t in touches {
            touchUpAtPoint(t.location(in: self))
        }
    }
}
#endif

#if os(macOS)

extension GameScene {
    override func keyDown(with event: NSEvent) {
        switch event.keyCode {
        case 124: // ->
            return
        case 123: // <-
            return
        default:
            return
        }
    }
    
    override func keyUp(with event: NSEvent) {
        switch event.keyCode {
        case 124: // ->
            return
        case 123: // <-
            return
        default:
            return
        }
    }
    
    override func mouseDown(with event: NSEvent) {
        touchDownAtPoint(event.location(in: self))
    }
    
    override func mouseDragged(with event: NSEvent) {
        touchMovedToPoint(event.location(in: self))
    }
    
    override func mouseUp(with event: NSEvent) {
        touchUpAtPoint(event.location(in: self))
    }
    
    // MARK: - View
        
    #if os(macOS)
    
    public func didChangeSize() {
    }
    
    #endif
}

#endif
