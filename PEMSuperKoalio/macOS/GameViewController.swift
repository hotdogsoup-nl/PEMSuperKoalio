import SpriteKit

class GameViewController: NSViewController, NSWindowDelegate {
    private var gameController = GameController()

    override func viewDidLoad() {
        super.viewDidLoad()

        if let skView = self.view as! SKView? {
            #if DEBUG
            skView.ignoresSiblingOrder = true
            skView.showsFPS = true
            skView.showsNodeCount = true
            skView.showsPhysics = false
            #endif
            
            gameController.view = skView
            gameController.startControl()
        }
    }
    
    override func viewDidAppear() {
        super.viewDidAppear()
        view.window?.delegate = self
        view.window?.acceptsMouseMovedEvents = true
    }
    
    func windowDidResize(_ notification: Notification) {
        gameController.windowDidResize()
    }
}
