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
    
    let moveAnalogStick =  🕹(diameter: 110)
    
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
        backgroundColor = UIColor.white
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
        
        //add snake & oppSnake
        creatSnake(snake: &mySnakeNodes)
        setUpCollisionBitMask(snake: &mySnakeNodes)
        
        //add opponent snake
        creatSnake(snake: &oppSnakeNodes)
        setUpCollisionBitMask(snake: &oppSnakeNodes)
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
                snake[0].position = CGPoint(x: snake[0].position.x + (data.velocity.x * 0.12), y: snake[0].position.y + (data.velocity.y * 0.12))
                // rotate head
                snake[0].zRotation = data.angular - 90
                // sent snake head position
                gameService.sendMove(snake[0].position, rotation: data.angular - 90)
                                
            } else {
                let rangeToSprite = SKRange(lowerLimit: 40, upperLimit: 40)
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
                let rangeToSprite = SKRange(lowerLimit: 40, upperLimit: 40)
                let distanceConstraint = SKConstraint.distance(rangeToSprite, to: oppSnakeNodes[index-1])
                // Define Constraints for orientation/targeting behavior
                let rangeForOrientation = SKRange(lowerLimit: 0, upperLimit: 0)
                let orientConstraint = SKConstraint.orient(to: oppSnakeNodes[0], offset: rangeForOrientation)
                // Add constraints
                snakeNode.constraints = [orientConstraint, distanceConstraint]
            }
        }
    }
    
    //creat a snake
    func creatSnake( snake: inout [SKSpriteNode]) {
        /* //random not working
        let x = UInt32(frame.size.width)
        let y = UInt32(frame.size.height)
        position = CGPoint(x: Int(arc4random() % x), y: Int(arc4random() % y))
        snake.append(addSnakeHead(CGPoint(x: position.x, y: position.y)))
        snake.append(addSnakeBody(CGPoint(x: position.x + 20, y: position.y)))
        snake.append(addSnakeBody(CGPoint(x: position.x + 40, y: position.y)))
        snake.append(addSnakeBody(CGPoint(x: position.x + 60, y: position.y)))
        snake.append(addSnakeBody(CGPoint(x: position.x + 80, y: position.y)))
        */
        snake.append(addSnakeHead(CGPoint(x: frame.midX, y: frame.midY)))
        snake.append(addSnakeBody(CGPoint(x: frame.midX + 40, y: frame.midY)))
        snake.append(addSnakeBody(CGPoint(x: frame.midX + 80, y: frame.midY)))
        snake.append(addSnakeBody(CGPoint(x: frame.midX + 120, y: frame.midY)))
        snake.append(addSnakeBody(CGPoint(x: frame.midX + 160, y: frame.midY)))

    }
    
    //adding head
    func addSnakeHead(_ position: CGPoint) ->  SKSpriteNode {
        let snakeImage = UIImage(named: "dragonHead")
        
        let texture = SKTexture(image: snakeImage!)
        let snakeHead = SKSpriteNode(texture: texture)
        snakeHead.physicsBody = SKPhysicsBody(texture: texture, size: CGSize(width: 45, height: 45) /*snakeHead.size*/)
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
        
        //collision & cotect
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

