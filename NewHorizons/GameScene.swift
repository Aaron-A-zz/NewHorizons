//
//  GameScene.swift
//  NewHorizons
//
//  Created by Aaron Ackerman on 12/9/15.
//  Copyright (c) 2015 Aaron A. All rights reserved.
//

import SpriteKit
import GameKit


struct PhysicsCatagory {
    static let asteroid : UInt32 = 1
    static let bullet : UInt32 = 2
    static let satellite : UInt32 = 4
    
}

class GameScene: SKScene, SKPhysicsContactDelegate {

    var satellite = SKSpriteNode()
    var pauseButton = SKSpriteNode()
    var playButton = SKSpriteNode()
    var minuteTimeLabel = SKLabelNode()
    var hourTimeLabel = SKLabelNode()
    var dayTimeLabel = SKLabelNode()
    var asteroidsDodgedLabel = SKLabelNode()
    var day = 0
    var hour = 0
    var minute = 0
    var dodgedAsteroids = 0
    let backgroundMusic = SKAudioNode(fileNamed: "NewYork.mp3")
    
    override func didMoveToView(view: SKView) {
        
        //Setting up Physics for the World!
        physicsWorld.contactDelegate = self
        physicsWorld.gravity = CGVectorMake(0.0, -0.9)
        
        //Background Music
        backgroundMusic.autoplayLooped = true
        addChild(backgroundMusic)
        
        //Adding Stars
        if let stars = SKEmitterNode(fileNamed: "movingStars") {
        stars.position = CGPoint(x: frame.size.width / 2, y: frame.size.height)
        stars.zPosition = -1
        addChild(stars)
        }
        
        /* Setup your scene here */
        satellite = childNodeWithName("satellite") as! SKSpriteNode
        satellite.physicsBody?.categoryBitMask = PhysicsCatagory.satellite
        satellite.physicsBody?.contactTestBitMask = PhysicsCatagory.asteroid
        playButton = childNodeWithName("playButton") as! SKSpriteNode
        playButton.hidden = true
        pauseButton = childNodeWithName("pauseButton") as! SKSpriteNode
        minuteTimeLabel = childNodeWithName("minuteTimeLable") as! SKLabelNode
        hourTimeLabel = childNodeWithName("hourTimeLabel") as! SKLabelNode
        dayTimeLabel = childNodeWithName("dayTimeLabel") as! SKLabelNode
        asteroidsDodgedLabel = childNodeWithName("asteroidsDodgedLabel") as! SKLabelNode
        
        //Spawn Asteroids
        let spawnRandomAsteroid = SKAction.runBlock(spawnAsteroid)
        let waitTime = SKAction.waitForDuration(0.5)
        let sequence = SKAction.sequence([spawnRandomAsteroid,waitTime])
        runAction((SKAction.repeatActionForever(sequence)), withKey: "spawnAsteroid")
        
        //Update Mission Clock
        let updateMissionTimeLabels = SKAction.runBlock(updateMissionTime)
        let updateTime = SKAction.waitForDuration(2.0)
        let updateSequence = SKAction.sequence([updateMissionTimeLabels,updateTime])
        runAction((SKAction.repeatActionForever(updateSequence)), withKey: "missionDurationTime")
        
    }
    
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        let touch = touches.first! as UITouch
        let touchLocation = touch.locationInNode(self)
        //print(touchLocation)
        
        let nodes = self.nodeAtPoint(touchLocation)
        if nodes.name == "pauseButton" {
            let showPlayButtonAction = SKAction.runBlock(showPlayButton)
            let pauseGameAction = SKAction.runBlock(pauseGame)
            let pauseSequence = SKAction.sequence([showPlayButtonAction, pauseGameAction])
            runAction(pauseSequence)
            
        } else if nodes.name == "playButton" {
            resumeGame()

            
        } else if nodes.name == "startGameButton" {
   
    
        } else {
            let moveTo = SKAction.moveTo(touchLocation, duration: 1.0)
            satellite.runAction(moveTo)
        }
        
        if touch.tapCount == 2 {
            //print("Fire The Cannons!")
            let shootBullets = SKAction.runBlock(SpawnBullets)
            runAction(shootBullets)
        }
        
    }
    
    func didBeginContact(contact: SKPhysicsContact) {
        
        let firstBody : SKPhysicsBody = contact.bodyA
        let secondBody : SKPhysicsBody = contact.bodyB
        
        if ((firstBody.node?.name == "asteroid" ) && (secondBody.node?.name == "bullet")) || ((firstBody.node?.name == "bullet" ) && (secondBody.node?.name == "asteroid"))  {
            
            CollisionWithBullet(firstBody.node as! SKSpriteNode, Bullet: secondBody.node as! SKSpriteNode)
            
        } else if ((firstBody.node?.name == "asteroid" ) && (secondBody.node?.name == "satellite")) || ((firstBody.node?.name == "satellite" ) && (secondBody.node?.name == "asteroid")) {
            
            CollisionWithAsteroid(secondBody.node as! SKSpriteNode, Satellite: firstBody.node as! SKSpriteNode)
            
        }
    }
    
    func CollisionWithBullet(Asteroid: SKSpriteNode, Bullet: SKSpriteNode) {
        Asteroid.removeFromParent()
        spawnBrokenAsteroid((Bullet.position))
        Bullet.removeFromParent()
    }
    
    func CollisionWithAsteroid(Asteroid: SKSpriteNode, Satellite: SKSpriteNode) {
        satellite.removeFromParent()
        Asteroid.removeFromParent()
        spawnBrokenSat(Satellite.position)
        spawnBrokenAsteroid(Asteroid.position)

        enumerateChildNodesWithName("asteroid") { //Changes the Asteroid name so its not counted after you die
            asteroid,_ in
            asteroid.name = "dontCountMe"
        }
        
        removeActionForKey("missionDurationTime")
        removeActionForKey("spawnAsteroid")
        runAction(SKAction.sequence([SKAction.waitForDuration(3),SKAction.runBlock(self.newGame)]))
        
    }
    
    func spawnBrokenAsteroid(contactPoint: CGPoint ) {
        let broken1 = SKSpriteNode(imageNamed: "broken1")
        let broken2 = SKSpriteNode(imageNamed: "broken2")
        let broken3 = SKSpriteNode(imageNamed: "broken3")
        let broken4 = SKSpriteNode(imageNamed: "broken4")
        
        addChild(broken1)
        addChild(broken2)
        addChild(broken3)
        addChild(broken4)
        
        let waitTime = SKAction.waitForDuration(3.0)
        let actionDone = SKAction.removeFromParent()
        
        broken1.position = CGPoint(x: contactPoint.x - 50, y: contactPoint.y)
        broken1.physicsBody = SKPhysicsBody(texture: broken1.texture!, size: broken1.frame.size)
        broken1.physicsBody?.applyAngularImpulse(0.3)
        broken1.name = "broken1"
        broken1.runAction(SKAction.sequence([waitTime, actionDone]))
        
        broken2.position = CGPoint(x: contactPoint.x - 25, y: contactPoint.y + 50)
        broken2.physicsBody = SKPhysicsBody(texture: broken2.texture!, size: broken2.frame.size)
        broken2.physicsBody?.applyAngularImpulse(0.2)
        broken2.name = "broken2"
        broken2.runAction(SKAction.sequence([waitTime, actionDone]))
        
        broken3.position = CGPoint(x: contactPoint.x + 50, y: contactPoint.y + 25)
        broken3.physicsBody = SKPhysicsBody(texture: broken3.texture!, size: broken3.frame.size)
        broken3.physicsBody?.applyAngularImpulse(0.1)
        broken3.name = "broken3"
        broken3.runAction(SKAction.sequence([waitTime, actionDone]))
        
        broken4.position = CGPoint(x: contactPoint.x + 50, y: contactPoint.y - 25)
        broken4.physicsBody = SKPhysicsBody(texture: broken4.texture!, size: broken4.frame.size)
        broken4.physicsBody?.applyAngularImpulse(0.1)
        broken4.name = "broken4"
        broken4.runAction(SKAction.sequence([waitTime, actionDone]))
        
   
    }
    
    
    func spawnBrokenSat(contactPoint: CGPoint ) {
        let brokensat1 = SKSpriteNode(imageNamed: "brokenSat1")
        let brokensat2 = SKSpriteNode(imageNamed: "brokenSat2")
        let brokensat3 = SKSpriteNode(imageNamed: "brokenSat3")
    
        addChild(brokensat1)
        addChild(brokensat2)
        addChild(brokensat3)
        
        let waitTime = SKAction.waitForDuration(3.0)
        let actionDone = SKAction.removeFromParent()
        
        brokensat1.position = CGPoint(x: contactPoint.x - 50, y: contactPoint.y)
        brokensat1.physicsBody = SKPhysicsBody(texture: brokensat1.texture!, size: brokensat1.frame.size)
        brokensat1.physicsBody?.applyAngularImpulse(0.3)
        brokensat1.name = "brokensat1"
        brokensat1.runAction(SKAction.sequence([waitTime, actionDone]))
        
        brokensat2.position = CGPoint(x: contactPoint.x - 25, y: contactPoint.y + 50)
        brokensat2.physicsBody = SKPhysicsBody(texture: brokensat2.texture!, size: brokensat2.frame.size)
        brokensat2.physicsBody?.applyAngularImpulse(0.2)
        brokensat2.name = "brokensat2"
        brokensat2.runAction(SKAction.sequence([waitTime, actionDone]))
        
        brokensat3.position = CGPoint(x: contactPoint.x + 50, y: contactPoint.y + 25)
        brokensat3.physicsBody = SKPhysicsBody(texture: brokensat3.texture!, size: brokensat3.frame.size)
        brokensat3.physicsBody?.applyAngularImpulse(0.1)
        brokensat3.name = "brokensat3"
        brokensat3.runAction(SKAction.sequence([waitTime, actionDone]))
        
    }



    func randomNumber(min min: CGFloat, max: CGFloat) -> CGFloat {
        let random = CGFloat(GKRandomSource.sharedRandom().nextUniform())
        return random * (max - min) + min / 1
    }
    
    
    func spawnAsteroid() {
        
        let randomAsteroidSize = ["SmallAsteroid","LargeAsteroid","xSmallAsteroid"]
        func getAsteroidSize() -> String {
            let randomNumber = GKRandomSource.sharedRandom().nextIntWithUpperBound(randomAsteroidSize.count)
            return randomAsteroidSize[randomNumber]
        }
        
        let asteroid = SKSpriteNode(imageNamed: "\(getAsteroidSize())")
        asteroid.position = CGPoint(x: frame.size.width * randomNumber(min: 0, max: 1), y: frame.size.height + asteroid.size.height)
        asteroid.physicsBody = SKPhysicsBody(texture: asteroid.texture!, size: asteroid.frame.size)
        asteroid.physicsBody?.categoryBitMask = PhysicsCatagory.asteroid
        asteroid.physicsBody?.contactTestBitMask = PhysicsCatagory.satellite
        asteroid.physicsBody?.contactTestBitMask = PhysicsCatagory.bullet
        asteroid.physicsBody?.dynamic = true
        asteroid.name = "asteroid"
        addChild(asteroid)
        
        let rotateAsteroid = SKAction.rotateByAngle(randomNumber(min: 1, max: 8), duration: 12)
        asteroid.runAction(rotateAsteroid, withKey: "rotateAsteroid")
        let actionDone = SKAction.removeFromParent()
        asteroid.runAction(SKAction.sequence([rotateAsteroid,actionDone]))
        
    }
    
    func SpawnBullets(){
        let bullet = SKSpriteNode(imageNamed: "bullet.png")
        bullet.position = CGPointMake(satellite.position.x, satellite.position.y + 75)
        let action = SKAction.moveToY(self.size.height + 10, duration: 0.5)
        let actionDone = SKAction.removeFromParent()
        bullet.runAction(SKAction.sequence([action, actionDone]))
        bullet.physicsBody?.categoryBitMask = PhysicsCatagory.bullet
        bullet.physicsBody?.contactTestBitMask = PhysicsCatagory.asteroid
        bullet.physicsBody = SKPhysicsBody(rectangleOfSize: bullet.size)
        bullet.physicsBody?.affectedByGravity = false
        bullet.physicsBody?.dynamic = false
        bullet.name = "bullet"
        self.addChild(bullet)
        
    }

    func updateMissionTime() {
        minute++
        
        if  minute == 60 {
            hour++
            minute = 0
        }
        
        if hour == 24 {
            day++
            hour = 0
        }
        minuteTimeLabel.text = "\(minute)"
        hourTimeLabel.text = "\(hour)"
        dayTimeLabel.text = "\(day)"
    }

    
    func pauseGame() {
        self.view!.paused = true
    }
    
    func resumeGame() {
        playButton.hidden = true
        pauseButton.hidden = false
        self.view?.paused = false
        
    }
    
    func showPlayButton() {
        pauseButton.hidden = true
        playButton.hidden = false
    }
    
    func newGame() {
        if  let scene = GameScene(fileNamed:"GameScene") {
                
            scene.scaleMode = .AspectFill
            view?.presentScene(scene)
        }
    }
   
    override func update(currentTime: CFTimeInterval) {
        /* Called before each frame is rendered */
        enumerateChildNodesWithName("asteroid") {
            asteroid,_ in
            if asteroid.position.y <= 3 {
                let newdodgeCount = ++self.dodgedAsteroids
                self.asteroidsDodgedLabel.text = "\(newdodgeCount)"
                asteroid.removeFromParent()
            }
            
        }
        
    }
}
