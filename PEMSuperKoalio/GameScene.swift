// Based on Ray Wenderlichs SpriteKit SuperKoalio game tutorial by Jake Gunderson.
// https://www.raywenderlich.com/2554-sprite-kit-tutorial-how-to-make-a-platform-game-like-super-mario-brothers-part-1

import SpriteKit
import PEMTileMap

let LayerNameScreenLayout = "ScreenLayout"
let LayerNameTerrain = "Terrain"
let LayerNameSpawn = "Spawn"

class GameScene: SKScene, SKPhysicsContactDelegate {
    private enum TileQueryPosition: Int {
        case above = 1
        case aboveLeft = 0
        case aboveRight = 2
        case below = 7
        case belowLeft = 6
        case belowRight = 8
        case toTheLeft = 3
        case toTheRight = 5
    }
    
    private var map: PEMTileMap?
    private var cameraNode: SKCameraNode
    private var mapLoaded = false
    private var previousTouchLocation = CGPoint.zero

    private var player: Player?
    private var previousUpdateTime = TimeInterval(0)
    private var walls: PEMTileLayer?
    private var hazards: PEMTileLayer?
    
    private var gameOver = false
    
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
            player?.position = newMap.position(tileCoords: CGPoint(x: 7, y: 15), centered: true)
            player?.zPosition = newMap.highestZPosition + 1
            newMap.addChild(player!)
            
            run(SKAction.repeatForever(SKAction.playSoundFileNamed("level1.mp3", waitForCompletion: true)))
            mapLoaded = true
        }
    }
        
    // MARK: - Game cycle
        
    override open func update(_ currentTime: TimeInterval) {
        guard mapLoaded else { return }
        guard !gameOver else { return }

        super.update(currentTime)

        var delta = currentTime - previousUpdateTime

        if (delta > 0.02) {
            delta = 0.02;
        }

        self.previousUpdateTime = currentTime;
        
        player?.update(delta)
        checkForAndResolveCollisionsForPlayer()
        checkForWin()
        setViewpointCenter()
    }
    
    // MARK: - Collision detection
    
    private func checkForAndResolveCollisionsForPlayer() {
        let tileQueryPositions : [TileQueryPosition] = [.below, .above, .toTheLeft, .toTheRight, .aboveLeft, .aboveRight, .belowLeft, .belowRight]
        player?.onGround = false
        
        for tileQueryPosition in tileQueryPositions {
            let playerRect = player?.collisionBoundingBox()
            let playerPosition = player!.desiredPosition
            let playerCoord = map!.tileCoords(positionInPoints: playerPosition)
            
            if playerCoord.y > map!.mapSizeInTiles().height + 1 {
                gameOver(won: false)
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
                        break
                    case .above:
//                        player!.desiredPosition = CGPoint(x: player!.desiredPosition.x, y: player!.desiredPosition.y - intersection.size.height)
                        break
                    case .toTheLeft:
//                        player!.desiredPosition = CGPoint(x: player!.desiredPosition.x + intersection.size.width, y: player!.desiredPosition.y)
                        break
                    case .toTheRight:
//                        player!.desiredPosition = CGPoint(x: player!.desiredPosition.x - intersection.size.width, y: player!.desiredPosition.y)
                        break
                    case .aboveLeft:
                        break
                    case .aboveRight:
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
    
    private func checkForWin() {
        guard mapLoaded else { return }

        if player!.position.x > map!.mapSizeInPoints().width * 0.95 {
            gameOver(won: true)
        }
    }
        
    private func gameOver(won: Bool) {
        gameOver = true
        run(SKAction.playSoundFileNamed("hurt.wav", waitForCompletion: true))
    }
    
    // MARK: - Input handling

    private func touchDownAtPoint(_ pos: CGPoint) {
        previousTouchLocation = pos
        
        if pos.x > size.width * 0.5 {
            player?.mightAsWellJump = true
        } else {
            player?.forwardMarch = true
        }
    }

    private func touchMovedToPoint(_ pos: CGPoint) {
        let halfWidth = size.width * 0.5
                
        if pos.x > halfWidth && previousTouchLocation.x <= halfWidth {
          player?.forwardMarch = false
          player?.mightAsWellJump = true
        } else if previousTouchLocation.x > halfWidth && pos.x <= halfWidth {
          player?.forwardMarch = true
          player?.mightAsWellJump = false
        }
        
        previousTouchLocation = pos
    }

    private func touchUpAtPoint(_ pos: CGPoint) {
        if pos.x > size.width * 0.5 {
            player?.mightAsWellJump = false
        } else {
            player?.forwardMarch = false
        }
    }
    
    // MARK: - Camera
    
    private func setViewpointCenter() {
        guard mapLoaded else { return }
                
        if let playerPosition = player?.position {
            let baseCameraPositionX = map!.mapSizeInPoints().width * -0.5 + size.width * 0.5 * cameraNode.xScale
            let baseCameraPositionY = map!.mapSizeInPoints().height * -0.5 + size.height * 0.5 * cameraNode.yScale

            var x = max(playerPosition.x, size.width * 0.5 * cameraNode.xScale) - size.width * 0.5 * cameraNode.xScale
            var y = max(playerPosition.y, size.height * 0.5 * cameraNode.yScale) - size.height * 0.5 * cameraNode.yScale
            x = min(x, map!.mapSizeInPoints().width - size.width * 0.5)
            y = min(y, map!.mapSizeInPoints().height - size.height * 0.5)

            let newCameraPositionX = max(baseCameraPositionX, baseCameraPositionX + x)
            let newCameraPositionY = max(baseCameraPositionY, baseCameraPositionY + y)
            
            cameraNode.position = CGPoint(x: newCameraPositionX, y: newCameraPositionY)
        }
    }
}

#if os(iOS) || os(tvOS)
extension GameScene {
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        for t in touches {
            touchDownAtPoint(t.location(in: view))
        }
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        for t in touches {
            touchMovedToPoint(t.location(in: view))
        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        for t in touches {
            touchUpAtPoint(t.location(in: view))
        }
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        for t in touches {
            touchUpAtPoint(t.location(in: view))
        }
    }
}
#endif

#if os(macOS)

extension GameScene {
    override func keyDown(with event: NSEvent) {
        switch event.keyCode {
        case 124: // ->
            player?.forwardMarch = true
        case 49: // Space
            player?.mightAsWellJump = true
        default:
            return
        }
    }
    
    override func keyUp(with event: NSEvent) {
        switch event.keyCode {
        case 124: // ->
            player?.forwardMarch = false
        case 49: // Space
            player?.mightAsWellJump = false
        default:
            return
        }
    }
    
    override func mouseDown(with event: NSEvent) {
        let location = event.locationInWindow
        touchDownAtPoint(CGPoint(x: location.x, y: size.height - location.y))
    }
    
    override func mouseDragged(with event: NSEvent) {
        let location = event.locationInWindow
        touchMovedToPoint(CGPoint(x: location.x, y: size.height - location.y))
    }
    
    override func mouseUp(with event: NSEvent) {
        let location = event.locationInWindow
        touchUpAtPoint(CGPoint(x: location.x, y: size.height - location.y))
    }
    
    // MARK: - View
        
    #if os(macOS)
    
    public func didChangeSize() {
    }
    
    #endif
}

#endif
