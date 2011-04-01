#define PTM_RATIO 32

#import "iPongLayer.h"


@implementation iPongLayer

+ (id)scene {
    
    CCScene *scene = [CCScene node];
    iPongLayer *layer = [iPongLayer node];
    [scene addChild:layer];
    return scene;
    
}

- (void)setupWorld {
    // Create a world
    b2Vec2 gravity = b2Vec2(0.0f, 0.0f);
    bool doSleep = true;
    _world = new b2World(gravity, doSleep);
}

- (void)setupGroundBody {
    CGSize winSize = [CCDirector sharedDirector].winSize;
    
    // Create edges around the entire screen
    b2BodyDef groundBodyDef;
    groundBodyDef.position.Set(0,0);
    _groundBody = _world->CreateBody(&groundBodyDef);
    b2PolygonShape groundBox;
    b2FixtureDef groundBoxDef;
    groundBoxDef.shape = &groundBox;
    groundBox.SetAsEdge(b2Vec2(0,0), b2Vec2(winSize.width/PTM_RATIO, 0));
    _bottomFixture = _groundBody->CreateFixture(&groundBoxDef);
    groundBox.SetAsEdge(b2Vec2(0,0), b2Vec2(0, winSize.height/PTM_RATIO));
    _groundBody->CreateFixture(&groundBoxDef);
    groundBox.SetAsEdge(b2Vec2(0, winSize.height/PTM_RATIO), b2Vec2(winSize.width/PTM_RATIO, winSize.height/PTM_RATIO));
    _groundBody->CreateFixture(&groundBoxDef);
    groundBox.SetAsEdge(b2Vec2(winSize.width/PTM_RATIO, winSize.height/PTM_RATIO), b2Vec2(winSize.width/PTM_RATIO, 0));
    _groundBody->CreateFixture(&groundBoxDef);
}

- (void)setupPlayer1Brick{
    CCSprite *brick = [CCSprite spriteWithFile:@"whitedot.png"
                                           rect:CGRectMake(50, 50, 50, 50)];
    brick.position = ccp(10,10);
    [self addChild:brick];
    
    b2BodyDef brickBodyDef;
    brickBodyDef.type = b2_dynamicBody;
    brickBodyDef.position.Set(brick.position.x/PTM_RATIO, 
                              brick.position.y/PTM_RATIO);
    brickBodyDef.userData = brick;
    _p1BrickBody = _world->CreateBody(&brickBodyDef);
    
    b2PolygonShape brickShape;
    brickShape.SetAsBox(brick.contentSize.width/PTM_RATIO/2,
                         brick.contentSize.height/PTM_RATIO/2);
    b2FixtureDef brickShapeDef;
    brickShapeDef.shape = &brickShape;
    brickShapeDef.density = 10.0;
    brickShapeDef.isSensor = true;
    _p1BrickFixture = _p1BrickBody->CreateFixture(&brickShapeDef);
}

- (void) setupBall{
    // Create Ball sprite.
    CCSprite *ball = [CCSprite spriteWithFile:@"Ball.png"
                                         rect:CGRectMake(0,0,52,52)];
    ball.position = ccp(100,100);
    ball.tag = 1;
    [self addChild:ball];
    
    // Create ball body 
    b2BodyDef ballBodyDef;
    ballBodyDef.type = b2_dynamicBody;
    ballBodyDef.position.Set(100/PTM_RATIO, 100/PTM_RATIO);
    ballBodyDef.userData = ball;
    b2Body * ballBody = _world->CreateBody(&ballBodyDef);
    
    // Create circle shape
    b2CircleShape circle;
    circle.m_radius = 26.0/PTM_RATIO;
    
    // Create shape definition and add to body
    b2FixtureDef ballShapeDef;
    ballShapeDef.shape = &circle;
    ballShapeDef.density = 1.0f;
    ballShapeDef.friction = 0.f;
    ballShapeDef.restitution = 1.0f;
    _ballFixture = ballBody->CreateFixture(&ballShapeDef);        
    b2Vec2 force = [self getStartingForce];
    ballBody->ApplyLinearImpulse(force, ballBodyDef.position);
}

- (void)ccTouchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    
    if (_mouseJoint != NULL) {
        return;
    }
    
    UITouch *myTouch = [touches anyObject];
    CGPoint location = [myTouch locationInView:[myTouch view]];
    location = [[CCDirector sharedDirector] convertToGL:location];
    b2Vec2 locationWorld = b2Vec2(location.x/PTM_RATIO, location.y/PTM_RATIO);
    
    if (_p1BrickFixture->TestPoint(locationWorld)) {
        b2MouseJointDef md;
        md.bodyA = _groundBody;
        md.bodyB = _p1BrickBody;
        md.target = locationWorld;
        md.collideConnected = true;
        md.maxForce = 1000.0f * _p1BrickBody->GetMass();
        
        _mouseJoint = (b2MouseJoint *)_world->CreateJoint(&md);
        _p1BrickBody->SetAwake(true);
    }
    
}

-(void)ccTouchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
    
    if (_mouseJoint == NULL) return;
    
    UITouch *myTouch = [touches anyObject];
    CGPoint location = [myTouch locationInView:[myTouch view]];
    location = [[CCDirector sharedDirector] convertToGL:location];
    b2Vec2 locationWorld = b2Vec2(location.x/PTM_RATIO, location.y/PTM_RATIO);
    
    _mouseJoint->SetTarget(locationWorld);
    
}

-(void)ccTouchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event {
    
    if (_mouseJoint) {
        _world->DestroyJoint(_mouseJoint);
        _mouseJoint = NULL;
    }
    
}

- (void)ccTouchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
    if (_mouseJoint) {
        _world->DestroyJoint(_mouseJoint);
        _mouseJoint = NULL;
    }  
}

- (id)init {
    
    if ((self=[super init])) {
        
        [self setupWorld];
        [self setupGroundBody];
        [self setupBall];
        [self setupPlayer1Brick];

        [self schedule:@selector(tick:)];
        
        self.isTouchEnabled = YES;
        
        // Restrict paddle along the x axis
        b2PrismaticJointDef jointDef;
        b2Vec2 worldAxis(1.0f, 0.0f);
        jointDef.collideConnected = true;
        jointDef.Initialize(_p1BrickBody, _groundBody, 
                            _p1BrickBody->GetWorldCenter(), worldAxis);
        _world->CreateJoint(&jointDef);
    }
    return self;
}

- (b2Vec2) getStartingForce{
    return b2Vec2(10,10);
}

- (void)tick:(ccTime) dt {
    _world->Step(dt, 10, 10);
    
    for(b2Body *b = _world->GetBodyList(); b; b=b->GetNext()) {
        CCSprite *sprite = (CCSprite *)b->GetUserData();
        
        if(sprite != NULL) {
            sprite.position = ccp(b->GetPosition().x * PTM_RATIO,
                                  b->GetPosition().y * PTM_RATIO);
            sprite.rotation = -1 * CC_RADIANS_TO_DEGREES(b->GetAngle());
        }
    }
}

- (void)dealloc {
    delete _world;
    _groundBody = NULL;
    [super dealloc];
}

@end