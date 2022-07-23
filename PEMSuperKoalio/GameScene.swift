import SpriteKit
import PEMTileMap

let LayerNameScreenLayout = "ScreenLayout"
let LayerNameTerrain = "Terrain"
let LayerNameSpawn = "Spawn"

protocol GameSceneDelegate {
    func restartGame()
}

class GameScene: SKScene {
    private enum TileQueryPosition: Int {
        case aboveLeft = 0
        case above = 1
        case aboveRight = 2
        case toTheLeft = 3
        case toTheRight = 5
        case belowLeft = 6
        case below = 7
        case belowRight = 8
    }
    
    var gameSceneDelegate: GameSceneDelegate?
    
    private weak var skView: SKView?
    private var map: PEMTileMap?
    private var cameraNode: SKCameraNode
    private var backgroundMusic: SKAudioNode
    private var mapLoaded = false
    private var previousTouchLocation = CGPoint.zero

    private var player: Player?
    private var previousUpdateTime = TimeInterval(0)
    private var walls: PEMTileLayer?
    private var hazards: PEMTileLayer?
    
    private var gameOver = false
    
#if os(iOS) || os(tvOS)
    private var replayButton: UIButton?
#else
    private var replayButton: NSButton?
#endif
    
    // MARK: - Init
    
    init(view: SKView, size: CGSize) {
        skView = view

        cameraNode = SKCameraNode()
        backgroundMusic = SKAudioNode(fileNamed: "level1.mp3")
        super.init(size: size)
        
        startControl()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Control

    private func startControl() {
        camera = cameraNode
        addChild(cameraNode)
        
        addLogo()
        loadMap()
    }
    
    private func addLogo() {
        let logo = SKSpriteNode(imageNamed: "PEMSuperKoalio")
        logo.anchorPoint = CGPoint(x: 0, y: 1)
        logo.position = CGPoint(x: size.width * -0.48, y: size.height * 0.48)
        camera?.addChild(logo)
    }
    
    private func loadMap() {
        if let newMap = PEMTileMap(mapName: "superkoalio.tmx", view: skView!) {
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
            
            addChild(backgroundMusic)
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
        handleHazardCollisions()
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
                    case .above:
                        player!.desiredPosition = CGPoint(x: player!.desiredPosition.x, y: player!.desiredPosition.y - intersection.size.height)
                        player!.velocity = CGPoint(x: player!.velocity.x, y: 0.0)
                    case .toTheLeft:
                        player!.desiredPosition = CGPoint(x: player!.desiredPosition.x + intersection.size.width, y: player!.desiredPosition.y)
                    case .toTheRight:
                        player!.desiredPosition = CGPoint(x: player!.desiredPosition.x - intersection.size.width, y: player!.desiredPosition.y)
                    default:
                        if (intersection.size.width > intersection.size.height) {
                            //tile is diagonal, but resolving collision vertically
                            //4
                            var intersectionHeight = CGFloat(0)
                            
                            if tileQueryPosition == .belowRight || tileQueryPosition == .aboveRight {
                                intersectionHeight = intersection.size.height
                                player?.onGround = true
                            } else {
                                intersectionHeight = -intersection.size.height
                            }
                            player?.desiredPosition = CGPoint(x: player!.desiredPosition.x, y: player!.desiredPosition.y + intersectionHeight)
                        } else {
                            //tile is diagonal, but resolving horizontally
                            var intersectionWidth = CGFloat(0)
                            
                            if tileQueryPosition == .belowLeft || tileQueryPosition == .aboveLeft {
                                intersectionWidth = intersection.size.width
                            } else {
                                intersectionWidth = -intersection.size.width
                            }
                            //5
                            player?.desiredPosition = CGPoint(x: player!.desiredPosition.x  + intersectionWidth, y: player!.desiredPosition.y)
                        }
                    }
                }
            }
        }
        
        //6
        player?.position = player!.desiredPosition
    }
    
    private func handleHazardCollisions() {
        let tileQueryPositions : [TileQueryPosition] = [.below, .above, .toTheLeft, .toTheRight, .aboveLeft, .aboveRight, .belowLeft, .belowRight]
        
        for tileQueryPosition in tileQueryPositions {
            let playerRect = player?.collisionBoundingBox()
            let playerPosition = player!.desiredPosition
            let playerCoord = map!.tileCoords(positionInPoints: playerPosition)

            let tileColumn = tileQueryPosition.rawValue % 3
            let tileRow = tileQueryPosition.rawValue / 3
            let tileCoord = CGPoint(x: Int(playerCoord.x) + tileColumn - 1, y: Int(playerCoord.y) + tileRow - 1)
            
            if let tileFound = map!.tileAt(tileCoords: tileCoord, inLayer: hazards!) {
                let tileRect = tileFound.frame

                //1
                if playerRect!.intersects(tileRect) {
                    gameOver(won: false)
                }
            }
        }
    }
    
    // MARK: - Game sequence
    
    private func checkForWin() {
        if player!.position.x > map!.mapSizeInPoints().width * 0.95 {
            gameOver(won: true)
        }
    }
            
    private func gameOver(won: Bool) {
        gameOver = true
        run(SKAction.playSoundFileNamed("hurt.wav", waitForCompletion: true))
        
        //1
        let endGameLabel = SKLabelNode(fontNamed: "Marker Felt")
        endGameLabel.text = won ? "You Won!" : "You have Died!"
        endGameLabel.fontSize = 40
        endGameLabel.position = CGPoint(x: 0, y: size.height * 0.2)
        camera?.addChild(endGameLabel)
        
        //2
        #if os(iOS)
        
        replayButton = UIButton(type: .custom)
        replayButton!.tag = 321
        let replayImage = UIImage(named: "replay")!
        replayButton!.setImage(replayImage, for: .normal)
        replayButton!.addTarget(self, action: #selector(replay), for: .touchUpInside)
        replayButton!.frame = CGRect(x: size.width / 2.0 - replayImage.size.width / 2.0, y: size.height / 2.0 - replayImage.size.height / 2.0, width: replayImage.size.width, height: replayImage.size.height)
        view?.addSubview(replayButton!)
        
        #elseif os(tvOS)
        
        replayButton = UIButton(type: .custom)
        replayButton!.tag = 321
        let replayImage = UIImage(named: "replay")!
        replayButton!.setImage(replayImage, for: .normal)
        replayButton!.addTarget(self, action: #selector(replay), for: .primaryActionTriggered)
        replayButton!.frame = CGRect(x: size.width / 2.0 - replayImage.size.width / 2.0, y: size.height / 2.0 - replayImage.size.height / 2.0, width: replayImage.size.width, height: replayImage.size.height)
        view?.addSubview(replayButton!)
        setNeedsFocusUpdate()
        updateFocusIfNeeded()
        
        #elseif os(macOS)
        
        let replayImage = NSImage(named: "replay")!
        let replayButton = NSButton(image: replayImage, target: self, action: #selector(replay))
        replayButton.bezelStyle = .shadowlessSquare
        replayButton.isBordered = false
        replayButton.imagePosition = .imageOnly
        replayButton.tag = 321
        replayButton.frame = CGRect(x: size.width / 2.0 - replayImage.size.width / 2.0, y: size.height / 2.0 - replayImage.size.height / 2.0, width: replayImage.size.width, height: replayImage.size.height)
        view?.addSubview(replayButton)
        #endif
    }
    
    //3
    @objc private func replay() {
        backgroundMusic.run(SKAction.stop())
        view?.viewWithTag(321)?.removeFromSuperview()
        gameSceneDelegate?.restartGame()
    }
    
    // MARK: - Input handling

#if os(iOS)
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
#endif
    
#if os(tvOS)
    private func touchDownAtPoint(_ pos: CGPoint) {
        previousTouchLocation = pos
    }

    private func touchMovedToPoint(_ pos: CGPoint) {
        player?.forwardMarch = pos.x > previousTouchLocation.x
    }

    private func touchUpAtPoint(_ pos: CGPoint) {
        player?.forwardMarch = false
    }
#endif
    
#if os(macOS)
    private func touchDownAtPoint(_ pos: CGPoint) {
    }

    private func touchMovedToPoint(_ pos: CGPoint) {
        player?.forwardMarch = pos.x > size.width * 0.5
    }

    private func touchUpAtPoint(_ pos: CGPoint) {
        player?.forwardMarch = false
    }
#endif
    
    // MARK: - Camera
    
    private func setViewpointCenter() {
        map!.moveCamera(toPoint: player!.position, sceneSize: size, duration: 0)
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

#if os(tvOS)
extension GameScene {
    override func pressesBegan(_ presses: Set<UIPress>, with event: UIPressesEvent?) {
        player?.mightAsWellJump = true
    }

    override func pressesChanged(_ presses: Set<UIPress>, with event: UIPressesEvent?) {
    }

    override func pressesEnded(_ presses: Set<UIPress>, with event: UIPressesEvent?) {
        player?.mightAsWellJump = false
    }

    override func pressesCancelled(_ presses: Set<UIPress>, with event: UIPressesEvent?) {
        player?.mightAsWellJump = false
    }
    
    override var preferredFocusedView: UIView? {
         return replayButton
    }
    
    override var preferredFocusEnvironments: [UIFocusEnvironment] {
        return [replayButton!]
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
        player?.mightAsWellJump = true
    }
    
    override func mouseMoved(with event: NSEvent) {
        let location = event.locationInWindow
        touchMovedToPoint(CGPoint(x: location.x, y: size.height - location.y))
    }
    
    override func mouseDragged(with event: NSEvent) {
    }
    
    override func mouseUp(with event: NSEvent) {
        player?.mightAsWellJump = false
    }
    
    public func didChangeSize() {
    }
}
#endif
