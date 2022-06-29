import Foundation
import SpriteKit
#if os(macOS)
import Cocoa
#else
import UIKit
#endif

public class GameController: NSObject, GameSceneDelegate {
    weak public var view: SKView?
    private var currentScene : GameScene?
    
    // MARK: - Life cycle
    
    override public init() {
        super.init()
    }

    public init(view: SKView) {
        super.init()
        self.view = view
    }
    
    // MARK: - Control
    
    public func startControl() {
        loadGameScene()
    }
    
    private func loadGameScene() {
        DispatchQueue.main.async { [unowned self] in            
            let nextScene = GameScene(view:view!, size: view!.bounds.size)
            nextScene.scaleMode = .aspectFill
            currentScene = nextScene
            currentScene?.gameSceneDelegate = self

            let transition = SKTransition.fade(withDuration: 0.3)
            view!.presentScene(nextScene, transition: transition)
        }
    }
    
    // MARK: - GameSceneDelegate
    
    func restartGame() {
        loadGameScene()
    }
    
    // MARK: - Apple Remote
    
#if os(tvOS)
    func pressesBegan(_ presses: Set<UIPress>, with event: UIPressesEvent?) {
        currentScene?.pressesBegan(presses, with: event)
    }
    
    func pressesChanged(_ presses: Set<UIPress>, with event: UIPressesEvent?) {
        currentScene?.pressesChanged(presses, with: event)
    }
    
    func pressesEnded(_ presses: Set<UIPress>, with event: UIPressesEvent?) {
        currentScene?.pressesEnded(presses, with: event)
    }
    
    func pressesCancelled(_ presses: Set<UIPress>, with event: UIPressesEvent?) {
        currentScene?.pressesCancelled(presses, with: event)
    }
#endif
    
    // MARK: - View
    
    #if os(macOS)

    public func windowDidResize() {
        currentScene?.didChangeSize()
    }

    #endif
}
