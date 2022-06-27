<p align="center">
<a href="https://github.com/p-edge-media/PEMSuperKoalio"><img src="Doc/logo.png" height="150"/>
<p align="center">
<a href="https://swift.org"><img src="https://img.shields.io/badge/Swift-5-brightgreen.svg"></a>
<a href="https://developer.apple.com/download/more/"><img src="https://img.shields.io/badge/Xcode-orange.svg"></a>
<a href="https://www.apple.com"><img src="https://img.shields.io/badge/platforms-iOS%20%7C%20tvOS%20%7C%20macOS-red.svg"></a>
</p>

**PEMSuperKoalio** is a Swift 5 version of Ray Wenderlichs SpriteKit [SuperKoalio game][superkoalio-url]. It uses the [PEMTileMap][pemtilemap-url] framework to generate the game map and supports iOS, macOS and tvOS.

The SuperKoalio demo project helped me to get into games programming. It was originally made in Objective-C with the `Cocos2D` framework and later a `SpriteKit` version ws made. I decided to make a Swift version that uses [PEMTileMap][pemtilemap-url] instead of `JSTileMap` for the map generation.

<p align="center">
<img src="Doc/screenshot_macos.png" height="450"/>
</p>

The map format used is still the original TMX Map file. [TMX Map files][tmx-map-url] can be created and edited with [Tiled][tiled-url].

This project is intended as educational, expanding upon Ray Wenderlichs original tutorial and code.

## PEMSuperKoalio Game Features
- [X] load map using the `PEMTmxMap` framework
- [X] spawn player on the map
- [X] collision detection
- [X] level completed, win
- [X] game over
- [X] sound & music
- [X] input: touch screen control
- [X] input: keyboard and mouse
- [X] input: Apple TV remote controller
  
## License
Based on Ray Wenderlichs SpriteKit SuperKoalio game tutorial by Jake Gunderson.
For educational purposes only.
https://www.raywenderlich.com/2554-sprite-kit-tutorial-how-to-make-a-platform-game-like-super-mario-brothers-part-1

Created by Jake Gundersen on 12/27/13.
Copyright (c) 2013 Razeware, LLC. All rights reserved.

Converted to Swift as a derived work for educational purposes by M.J. van Spanje, P-Edge media in 2022. Some improvements and changes were added. If you believe your rights are being infringed upon, please contact me via https://www.p-edge.nl

[tmx-map-url]:https://doc.mapeditor.org/en/stable/reference/tmx-map-format/#
[tiled-url]:http://www.mapeditor.org
[pemtilemap-url]:https://github.com/hotdogsoup-nl/PEMTileMap
[superkoalio-url]:https://www.raywenderlich.com/2554-sprite-kit-tutorial-how-to-make-a-platform-game-like-super-mario-brothers-part-1
