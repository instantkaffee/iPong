#import "cocos2d.h"
#import "Box2D.h"

@interface Ball : NSObject {
    CCSprite* Sprite;
    b2Body* Body;
    b2Fixture* Fixture;
}

@property(readonly,assign) CCSprite* Sprite;
@property(readonly,assign) b2Body* Body;
@property(readonly,assign) b2Fixture* Fixture;

-(id) spawn: (CCLayer*) layer: (b2World*) world: (b2Body*) groundBody: (b2Vec2) force;
-(void)dealloc;
@end