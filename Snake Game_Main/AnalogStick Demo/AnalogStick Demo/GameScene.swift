//
//  GameScene.swift
//
//  Created by Dmitriy Mitrophanskiy on 28.09.14.
//  Copyright (c) 2014 Dmitriy Mitrophanskiy. All rights reserved.
//

//Note
// 2 start positions, 2 random num, compare, less goes o pos1 / 2 -todo

import SpriteKit

enum NodeType: UInt32 {
    case playerHead = 0x1 // 0001
    case playerBody = 0x2 // 0010
    case enemyHead = 0x4 // 0100
    case enemyBody = 0x8 // 1000
}

class GameScene: SKScene, SKPhysicsContactDelegate {
    //for collision detection
    //let headCategory: UInt32 = 0 //0x1 << 0
    //let bodyCategory: UInt32 = 1 //0x1 << 1
    
    var appleNode: SKSpriteNode?
    var mySnakeNodes: [SKSpriteNode] = []
    var oppSnakeNodes: [SKSpriteNode] = []
    
    // use for setting Alert View condition
    var gameOn = true;
    
    var joystickStickImageEnabled = true {
        didSet {
            let image = joystickStickImageEnabled ? UIImage(named: "jStick") : nil
            moveAnalogStick.stick.image = image
        }
    }
    
    var joystickSubstrateImageEnabled = true {
        didSet {
            let image = joystickSubstrateImageEnabled ? UIImage(named: "jSubstrate") : nil
            moveAnalogStick.substrate.image = image
        }
    }
    
    let moveAnalogStick =  🕹(diameter: 100)
    
    //multipeer conectivity
    let gameService = GameServiceManager()
    
    var connectionLable: UILabel?
    
    override func didMove(to view: SKView) {
        //multipeer conectivity
        gameService.delegate = self
        
        //contact & collision
        self.physicsWorld.contactDelegate = self

        //connection lable
        connectionLable = UILabel(frame: CGRect(x: 10, y: 10, width: 400, height: 21))
        connectionLable!.textAlignment = NSTextAlignment.left
        connectionLable!.text = "Connection: "
        self.view!.addSubview(connectionLable!)
        
        /* Setup your scene here */
        backgroundColor = UIColor.cyan
        physicsBody = SKPhysicsBody(edgeLoopFrom: frame)
        
        moveAnalogStick.position = CGPoint(x: moveAnalogStick.radius + 15, y: moveAnalogStick.radius + 15)
        addChild(moveAnalogStick)
        
        //MARK: Handlers begin
        
        moveAnalogStick.trackingHandler = { [unowned self] data in
            //move my snake
            let mySnake = self.mySnakeNodes
            self.snakeMove(data, snake: mySnake)
            //check for collision
            //self.collision = false
        }
        
        //MARK: Handlers end
        
        joystickStickImageEnabled = true
        joystickSubstrateImageEnabled = true
        
        //add opponent snake
        createEnemySnake(snake: &oppSnakeNodes)
        
        //add snake & oppSnake
        createPlayerSnake(snake: &mySnakeNodes)
        
        view.isMultipleTouchEnabled = true
    }
    
    // keep track of num of snakes
    var snakeCount = 0;

    //collision flag
    var collision = false
    //check collision
    func didBegin(_ contact: SKPhysicsContact) {
        
        /*
        //send alert message
        if(!collision) {
            print("撞上了！")
            //showPauseAlert()
            //not working - fix - update view??
            mySnakeNodes[0].position = CGPoint(x: 100, y: 100)
            //print(mySnakeNodes[0].position)
            collision = true
        }
        //self.presentViewController(alertController, animated: true, completion: nil)
        
        let firstNode = contact.bodyA.node as? SKSpriteNode
        let secondNode = contact.bodyB.node as? SKSpriteNode
        */
        if ( gameOn && ( ((Int(contact.bodyA.categoryBitMask) & Int(contact.bodyB.collisionBitMask)) != 0) || ((Int(contact.bodyB.categoryBitMask) & Int(contact.bodyA.collisionBitMask)) != 0) ) ) {
            
            print("看这里！！！！！！！！！！")
            gameOn = false;
            endGame()
        }
    }
    
    //move my snake
    func snakeMove(_ data: AnalogJoystickData, snake: [SKSpriteNode]) {
        
        for (index, snakeNode) in snake.enumerated() {
            //move head
            if index == 0 {
                snake[0].position = CGPoint(x: snake[0].position.x + (data.velocity.x * 0.15), y: snake[0].position.y + (data.velocity.y * 0.15))
                // rotate head
                snake[0].zRotation = data.angular - 3.14/2
                // sent snake head position
                gameService.sendMove(snake[0].position, rotation: data.angular - 3.14/2)
                                
            } else {
                var rangeToSprite = SKRange(lowerLimit: 10, upperLimit: 10)
                if index == 1 {
                    rangeToSprite = SKRange(lowerLimit: 15, upperLimit: 15)
                }
                let distanceConstraint = SKConstraint.distance(rangeToSprite, to: snake[index-1])
                // Define Constraints for orientation/targeting behavior
                let rangeForOrientation = SKRange(lowerLimit: 0, upperLimit: 0)
                let orientConstraint = SKConstraint.orient(to: snake[0], offset: rangeForOrientation)
                // Add constraints
                snakeNode.constraints = [orientConstraint, distanceConstraint]
            }
        }
        
    }
    
    //move opponent snake
    func oppSnakeMove(toPosition: CGPoint, rotation: CGFloat) {
        for (index, snakeNode) in oppSnakeNodes.enumerated() {
            if index == 0 {
                oppSnakeNodes[0].position = toPosition
                //print("rotation: " , rotation)
                oppSnakeNodes[0].zRotation = rotation
            } else {
                //改拐弯重心－头部
                var rangeToSprite = SKRange(lowerLimit: 10, upperLimit: 10)
                if index == 1 {
                    rangeToSprite = SKRange(lowerLimit: 15, upperLimit: 15)
                }
                let distanceConstraint = SKConstraint.distance(rangeToSprite, to: oppSnakeNodes[index-1])
                // Define Constraints for orientation/targeting behavior
                let rangeForOrientation = SKRange(lowerLimit: 0, upperLimit: 0)
                let orientConstraint = SKConstraint.orient(to: oppSnakeNodes[0], offset: rangeForOrientation)
                // Add constraints
                snakeNode.constraints = [orientConstraint, distanceConstraint]
            }
        }
    }
    
    //create an enemy snake
    func createEnemySnake( snake: inout [SKSpriteNode]) { //inout- pass by reference
        snake.append(addEnemySnakeHead(CGPoint(x: frame.midX, y: frame.midY)))
        for i in 1 ..< 13 {
            snake.append(addEnemySnakeBody(CGPoint(x: frame.midX + CGFloat(i*10), y: frame.midY)))
        }
    }
    
    //create a snake
    func createPlayerSnake( snake: inout [SKSpriteNode]) {
       
        let x = Int(arc4random_uniform(600)+10)
        var y: UInt32!
        repeat {
            y = arc4random_uniform(370)+10
        } while y == UInt32(frame.midY)
        
        snake.append(addPlayerSnakeHead(CGPoint(x: CGFloat(x), y: CGFloat(y))))
        
        for i in 1 ..< 13 {
            snake.append(addPlayerSnakeBody(CGPoint(x: CGFloat(x + i * 10), y: CGFloat(y))))
        }
        
    }
    //*********************************************************************************
    func addPlayerSnakeHead(_ position: CGPoint) ->  SKSpriteNode {
        let snakeImage = UIImage(named: "dragonHead")
        
        let texture = SKTexture(image: snakeImage!)
        let snakeHead = SKSpriteNode(texture: texture)
        snakeHead.physicsBody = SKPhysicsBody(texture: texture, size: CGSize(width: 40, height: 40) /*snakeHead.size*/)
        snakeHead.physicsBody!.affectedByGravity = false
        snakeHead.physicsBody!.allowsRotation = false
        snakeHead.physicsBody!.isDynamic = true    // ignore forces
        
        snakeHead.physicsBody!.categoryBitMask = NodeType.playerHead.rawValue
        snakeHead.physicsBody!.collisionBitMask = NodeType.enemyBody.rawValue
        snakeHead.physicsBody!.contactTestBitMask = NodeType.enemyBody.rawValue
        
        insertChild(snakeHead, at: 0)
        snakeHead.position = position
        //snakeNodes.append(snake)
        return snakeHead
    }
    
    func addEnemySnakeHead(_ position: CGPoint) ->  SKSpriteNode {
        let snakeImage = UIImage(named: "dragonHead")
        
        let texture = SKTexture(image: snakeImage!)
        let snakeHead = SKSpriteNode(texture: texture)
        snakeHead.physicsBody = SKPhysicsBody(texture: texture, size: CGSize(width: 40, height: 40) /*snakeHead.size*/)
        snakeHead.physicsBody!.affectedByGravity = false
        snakeHead.physicsBody!.allowsRotation = false
        snakeHead.physicsBody!.isDynamic = true    // ignore forces
        
        snakeHead.physicsBody!.categoryBitMask = NodeType.enemyHead.rawValue
        snakeHead.physicsBody!.collisionBitMask = NodeType.playerBody.rawValue
        snakeHead.physicsBody!.contactTestBitMask = NodeType.playerBody.rawValue
        
        insertChild(snakeHead, at: 0)
        snakeHead.position = position
        //snakeNodes.append(snake)
        return snakeHead
    }
    
    func addPlayerSnakeBody(_ position: CGPoint) ->  SKSpriteNode {
        let bodyImage = UIImage(named: "dragonBody")
        
        let texture = SKTexture(image: bodyImage!)
        let snakeBody = SKSpriteNode(texture: texture)
        snakeBody.physicsBody = SKPhysicsBody(texture: texture, size: snakeBody.size)
        snakeBody.physicsBody!.affectedByGravity =  false
        snakeBody.physicsBody!.allowsRotation = false
        snakeBody.physicsBody!.isDynamic = true    // ignore forces
        
        //collision & cotect
        snakeBody.physicsBody!.categoryBitMask = NodeType.playerBody.rawValue
        snakeBody.physicsBody!.collisionBitMask = NodeType.enemyHead.rawValue
        snakeBody.physicsBody!.contactTestBitMask = NodeType.enemyHead.rawValue
        
        insertChild(snakeBody, at: 0)
        snakeBody.position = position
        //snakeNodes.append(snakeBody)
        return snakeBody
    }
    
    func addEnemySnakeBody(_ position: CGPoint) ->  SKSpriteNode {
        let bodyImage = UIImage(named: "dragonBody")
        
        let texture = SKTexture(image: bodyImage!)
        let snakeBody = SKSpriteNode(texture: texture)
        snakeBody.physicsBody = SKPhysicsBody(texture: texture, size: snakeBody.size)
        snakeBody.physicsBody!.affectedByGravity =  false
        snakeBody.physicsBody!.allowsRotation = false
        snakeBody.physicsBody!.isDynamic = true    // ignore forces
        
        //collision & cotect
        snakeBody.physicsBody!.categoryBitMask = NodeType.enemyBody.rawValue
        snakeBody.physicsBody!.collisionBitMask = NodeType.playerHead.rawValue
        snakeBody.physicsBody!.contactTestBitMask = NodeType.playerHead.rawValue
        
        insertChild(snakeBody, at: 0)
        snakeBody.position = position
        //snakeNodes.append(snakeBody)
        return snakeBody
    }
    
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        /* Called when a touch begins */
        
        if let touch = touches.first {
            
            let node = atPoint(touch.location(in: self))
            /*
            switch node {
            //add other buttons
                //ex. speed up
                
            default:
                //add food
                addApple(touch.location(in: self))
            }*/
        }
    }
    
    override func update(_ currentTime: TimeInterval) {
        /* Called before each frame is rendered */
    }
    
    
    func endGame() {
        // disconnect from multipeer connectivity
        //disconnectFromMC(manager: GameServiceManager)
        self.gameService.session.disconnect()
        if (gameOn == false) {
            showPauseAlert();
            //gameOn = true;
        }
        
    }
}


extension GameScene : GameServiceManagerDelegate {
    
    func connectedDevicesChanged(_ manager: GameServiceManager, connectedDevices: [String]) {
        OperationQueue.main.addOperation { () -> Void in
            self.connectionLable!.text = "Connections: \(connectedDevices)"
        }
    }
    
    func receiveMove(_ manager: GameServiceManager, toPosition : CGPoint, rotation: CGFloat) {
        OperationQueue.main.addOperation { () -> Void in
            self.oppSnakeMove(toPosition: toPosition, rotation: rotation)
        }
    }
}

// alert message
private extension GameScene {
    func showPauseAlert() {
        let alertView = SIAlertView(title: "Game end!!", andMessage: "Congratulations! test testing bla bla bla")
        
        alertView?.addButton(withTitle: "Restart", type: .default) { (alertView) -> Void in
            self.gameOn = true;
            // reset the game
        }
        
        alertView?.show()
    }
}

