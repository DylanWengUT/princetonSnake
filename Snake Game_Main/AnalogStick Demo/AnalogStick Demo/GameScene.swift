//
//  GameScene.swift
//
//  Created by Dmitriy Mitrophanskiy on 28.09.14.
//  Copyright (c) 2014 Dmitriy Mitrophanskiy. All rights reserved.
//

//Note
// 2 start positions, 2 random num, compare, less goes o pos1 / 2 -todo

import SpriteKit


class GameScene: SKScene, SKPhysicsContactDelegate {
    //for collision detection
    //let headCategory: UInt32 = 0 //0x1 << 0
    //let bodyCategory: UInt32 = 1 //0x1 << 1
    
    var appleNode: SKSpriteNode?
    var mySnakeNodes: [SKSpriteNode] = []
    var oppSnakeNodes: [SKSpriteNode] = []
    
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
        setUpCollisionBitMask(snake: &oppSnakeNodes)
        
        //add snake & oppSnake
        createSnake(snake: &mySnakeNodes)
        setUpCollisionBitMask(snake: &mySnakeNodes)
       
        /*
        for node in oppSnakeNodes {
            insertChild(node, at: 0)
        }*/
        
        view.isMultipleTouchEnabled = true
    }
    
    // keep track of num of snakes
    var snakeCount = 0;
    
    func setUpCollisionBitMask(snake: inout [SKSpriteNode]) {
        for node in snake {
            node.physicsBody!.isDynamic = true
            node.physicsBody!.categoryBitMask = UInt32(snakeCount)
            // case: only 2 snakes, needs improvement
            if(snakeCount == 0) {
                node.physicsBody!.collisionBitMask = UInt32(1)
                node.physicsBody!.contactTestBitMask = UInt32(1)
            } else {
                node.physicsBody!.collisionBitMask = UInt32(0)
                node.physicsBody!.contactTestBitMask = UInt32(0)
            }
        }
        snakeCount += 1
    }

    //collision flag
    var collision = false
    //check collision
    func didBegin(_ contact: SKPhysicsContact) {
        
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
        /*
        let firstNode = contact.bodyA.node as! SKSpriteNode
        let secondNode = contact.bodyB.node as! SKSpriteNode
        
        if (contact.bodyA.categoryBitMask == bodyCategory) && (contact.bodyB.categoryBitMask == headCategory) {
            
            print("看这里！！！！！！！！！！")
            
            let contactPoint = contact.contactPoint
            let contact_y = contactPoint.y
            let target_y = secondNode.position.y
            let margin = secondNode.frame.size.height/2 - 25
            
            if (contact_y > (target_y - margin)) &&
                (contact_y < (target_y + margin)) {
                print("Hit")
            }
        }*/
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
        
        snake.append(addSnakeHead(CGPoint(x: frame.midX, y: frame.midY)))
        
        for i in 1 ..< 13 {
            snake.append(addSnakeBody(CGPoint(x: frame.midX + CGFloat(i*10), y: frame.midY)))
        }
    
    }
    //create a snake
    func createSnake( snake: inout [SKSpriteNode]) {
       
        let x = Int(arc4random_uniform(600)+10)
        var y: UInt32!
        repeat {
            y = arc4random_uniform(375)
        } while y == UInt32(frame.midY)
        
        snake.append(addSnakeHead(CGPoint(x: CGFloat(x), y: CGFloat(y))))
        
        for i in 1 ..< 13 {
            snake.append(addSnakeBody(CGPoint(x: CGFloat(x + i * 10), y: CGFloat(y))))
        }
        
    }

    
    //adding head
    func addSnakeHead(_ position: CGPoint) ->  SKSpriteNode {
        let snakeImage = UIImage(named: "dragonHead")
        
        let texture = SKTexture(image: snakeImage!)
        let snakeHead = SKSpriteNode(texture: texture)
        snakeHead.physicsBody = SKPhysicsBody(texture: texture, size: CGSize(width: 40, height: 40) /*snakeHead.size*/)
        snakeHead.physicsBody!.affectedByGravity = false
        snakeHead.physicsBody!.allowsRotation = false
        snakeHead.physicsBody!.isDynamic = false    // ignore forces
        
        insertChild(snakeHead, at: 0)
        snakeHead.position = position
        //snakeNodes.append(snake)
        return snakeHead
    }
    
    func addSnakeBody(_ position: CGPoint) ->  SKSpriteNode {
        let bodyImage = UIImage(named: "dragonBody")
        
        let texture = SKTexture(image: bodyImage!)
        let snakeBody = SKSpriteNode(texture: texture)
        snakeBody.physicsBody = SKPhysicsBody(texture: texture, size: snakeBody.size)
        snakeBody.physicsBody!.affectedByGravity =  false
        snakeBody.physicsBody!.allowsRotation = false
        snakeBody.physicsBody!.isDynamic = false    // ignore forces
        
        //collision & contact
        //snakeBody.physicsBody!.collisionBitMask = headCategory
        //snakeBody.physicsBody!.contactTestBitMask = headCategory
        
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
        let alertView = SIAlertView(title: "Edess!!", andMessage: "Congratulations! test testing bla bla bla")
        
        alertView?.addButton(withTitle: "OK", type: .default) { (alertView) -> Void in
            //self.collision = false
        }
        
        alertView?.show()
    }
}

