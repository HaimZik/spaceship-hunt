package
{
	import com.input.Key;
	import com.spaceshiptHunt.entities.EnemyAI;
	import com.spaceshiptHunt.entities.PhysicsParticle;
	import com.spaceshiptHunt.level.Level;
	import com.spaceshiptHunt.level.Environment;
	import com.spaceshiptHunt.entities.Player;
	import flash.geom.Matrix;
	import flash.geom.Point;
	import flash.media.SoundChannel;
	import flash.media.SoundTransform;
	import flash.ui.Keyboard;
	import io.arkeus.ouya.controller.Xbox360Controller;
	import io.arkeus.ouya.ControllerInput;
	import nape.geom.Vec2;
	import nape.phys.Body;
	import nape.phys.BodyType;
	import starling.animation.Juggler;
	import starling.core.Starling;
	import starling.display.Canvas;
	import starling.display.Image;
	import starling.display.MeshBatch;
	import starling.display.Sprite;
	import starling.events.EnterFrameEvent;
	import starling.events.Event;
	import starling.events.KeyboardEvent;
	import starling.events.ResizeEvent;
	import starling.events.Touch;
	import starling.events.TouchEvent;
	import starling.events.TouchPhase;
	import starling.textures.RenderTexture;
	import starling.textures.Texture;
	import starling.textures.TextureOptions;
	import starling.utils.Color;
	import starling.utils.Pool;
	CONFIG::debug
	{
		import com.spaceshiptHunt.level.EnvironmentBuilder;
		import nape.util.ShapeDebug;
		import nape.geom.Mat23;
		import DDLS.view.DDLSSimpleView;
	}
	
	/**
	 * ...
	 * @author Haim Shnitzer
	 */
	public class Game extends Sprite
	{
		private var player:Player;
		private var mousePosition:Point;
		private var joystickRadios:Number;
		//private var joystick:MeshBatch;
		private var joystickTranslation:Matrix = new Matrix();
		private var joystickPosition:Point;
		private var xboxController:Xbox360Controller;
		private var background:Image;
		private var backgroundRatio:Number;
		private var obstacleTexture:Image;
		private var backgroundMusic:SoundChannel;
		private var pointPool:Point = new Point();
		private var touches:Vector.<Touch> = new Vector.<Touch>();
		private var enemy:EnemyAI;
		CONFIG::release
		{
			private var obstacleMask:Canvas;
			private var gameEnvironment:Environment;
		}
		CONFIG::debug
		{
			private var obstacleMask:Sprite;
			private var lisDown:Boolean = false;
			private var gameEnvironment:EnvironmentBuilder;
			private var napeDebug:ShapeDebug;
			private var nevMeshView:DDLSSimpleView;
		}
		
		public function Game()
		{
			init();
		}
		
//-----------------------------------------------------------------------------------------------------------------------------------------
		//initialization functions		
		private function init():void
		{
			CONFIG::debug
			{
				obstacleMask = new Sprite();
				addChild(obstacleMask);
				gameEnvironment = new EnvironmentBuilder(obstacleMask);
				napeDebug = new ShapeDebug(Starling.current.stage.stageWidth, Starling.current.stage.stageHeight, 0x33333333);
				nevMeshView = new DDLSSimpleView();
				nevMeshView.surface.mouseEnabled = false;
				Starling.current.nativeOverlay.addChild(napeDebug.display);
				Starling.current.nativeOverlay.addChild(nevMeshView.surface);
			}
			CONFIG::release
			{
				gameEnvironment = new Environment();
				obstacleMask = new Canvas();
				addChild(obstacleMask);
			}
			//joystick = new MeshBatch();
			drawJoystick();
			Starling.current.start();
			Starling.current.stop();
			player = new Player(new Vec2(5200, 4720));
			gameEnvironment.player = this.player;
			gameEnvironment.enqueueBody("player", player.body, addChild(new Sprite()));
			enemy = new EnemyAI(new Vec2(4900, 4700), player);
			gameEnvironment.enqueueBody("batship", enemy.body, addChild(new Sprite()));
			gameEnvironment.enqueueBody("level1", new Body(BodyType.STATIC), obstacleMask);
			gameEnvironment.loadLevel(onFinishLoadingInfo);
		}
		
		private function onFinishLoadingInfo():void
		{
			Environment.assetsLoader.enqueue("grp/textureAtlases.xml");
			Environment.assetsLoader.enqueue("grp/textureAtlases.png");
			gameEnvironment.loadLevel(onFinishLoading);
		}
		
		private function onFinishLoading():void
		{
			background = new Image(Environment.assetsLoader.getTexture("stars"));
			obstacleTexture = new Image(Environment.assetsLoader.getTexture("concrete_baked"));
			background.tileGrid = Pool.getRectangle();
			obstacleTexture.tileGrid = Pool.getRectangle();
			addChildAt(background, 0);
			addChildAt(obstacleTexture, 1);
			backgroundRatio = Math.ceil(Math.sqrt(stage.stageHeight * stage.stageHeight + stage.stageWidth * stage.stageWidth) / 512) * 2;
			background.scale = backgroundRatio;
			obstacleTexture.scale = backgroundRatio;
			//updateImageOffset(obstacleTexture, backgroundRatio);
			obstacleTexture.mask = obstacleMask;
			mousePosition = new Point(stage.stageWidth, 0);
//			this.setChildIndex(joystick, numChildren);
			player.gunType = "fireCannon";
			Starling.current.start();
			Key.init(Starling.current.nativeStage);
			ControllerInput.initialize(Starling.current.nativeStage);
			addEventListener(KeyboardEvent.KEY_UP, keyUp);
			addEventListener(Event.ENTER_FRAME, enterFrame);
			addEventListener(TouchEvent.TOUCH, onTouch);
			Starling.current.stage.addEventListener(Event.RESIZE, stage_resize);
			Environment.assetsLoader.enqueueWithName("audio/Nihilore.mp3", "music");
			Environment.assetsLoader.loadQueue(function onProgress(ratio:Number):void
			{
				if (ratio == 1.0)
				{
					backgroundMusic = Environment.assetsLoader.getSound("music").play(0, 7);
					backgroundMusic.soundTransform = new SoundTransform(0.4);
				}
			})
			//	PhysicsParticle.fill.cache();
		}
		
		private function keyUp(e:KeyboardEvent, keyCode:int):void
		{
			if (keyCode == Keyboard.ENTER)
			{
				player.stopShooting();
			}
		}
		
		private function drawJoystick():void
		{
			joystickRadios = Math.min(600, Starling.current.stage.stageWidth, Starling.current.stage.stageHeight) / 4;
			//var joyShape:Canvas = new Canvas();
			//joyShape.beginFill(Color.GRAY, 0.3);
			//joyShape.drawCircle(joystickRadios, joystickRadios, joystickRadios);
			//joyShape.endFill();
			joystickPosition = new Point(joystickRadios + 20, Starling.current.stage.stageHeight - joystickRadios - 10);
			//var joystickTexture:RenderTexture = new RenderTexture(joystickRadios * 2, joystickRadios * 2);
			//joystickTexture.draw(joyShape);
			//joyShape.dispose();
			//var joystickImage:Image = new Image(joystickTexture);
			//joystick.pivotY = joystick.pivotX = joystickRadios;
			//joystick.x = joystickPosition.x;
			//joystick.y = joystickPosition.y;
			//joystick.addImage(joystickImage);
			//addChild(joystick);
			//joystickImage.pivotY = joystickImage.pivotX = joystickRadios;
			//joystickImage.y = joystickImage.x = joystickRadios;
			//joystickImage.scaleY = joystickImage.scaleX = 0.7;
			//joystick.addImage(joystickImage);
		}
		
//-----------------------------------------------------------------------------------------------------------------------------------------
		//event functions
		private function stage_resize(e:ResizeEvent = null):void
		{
			stage.stageWidth = e.width;
			stage.stageHeight = e.height;
			Starling.current.viewPort.width = e.width;
			Starling.current.viewPort.height = e.height;
			joystickRadios = int(Math.min(800, e.width, e.height) / 5);
			joystickPosition.setTo(joystickRadios + 20, e.height - joystickRadios - 20);
			//joystick.rotation = 0;
			//joystick.x = joystick.y = 0;
			//joystick.width = joystick.height = joystickRadios * 2;
		}
		
		private function onTouch(e:TouchEvent):void
		{
			touches.splice(0, touches.length);
			e.getTouches(this, null, touches);
			if (touches.length == 1)
			{
				touches[0].getLocation(this, mousePosition);
				if (touches[0].phase == TouchPhase.ENDED)
				{
					mousePosition.setTo(stage.stageWidth, 0);
					player.stopShooting();
				}
				else
				{
					CONFIG::release
					{
						CONFIG::desktop
						{
							if (touches[0].phase == TouchPhase.BEGAN)
							{
								player.startShooting();
							}
						}
					}
					touches[0].getLocation(this.parent, mousePosition);
					mousePosition.offset(-joystickPosition.x, -joystickPosition.y);
				}
				CONFIG::debug
				{
					if (mousePosition.length > 250)
					{
						//calls LevelBuilder handleTouch
						gameEnvironment.handleTouch(e);
					}
				}
			}
//else //if (touches.length >= 2)
//{
			//touch = touches[1];
			//currentPos = touch.getLocation(this);
			//pathfinder.findPath(currentPos.x, currentPos.y, path);
//}else if (touches.length==0)
//{
			//touches = e.getTouches(this, TouchPhase.MOVED);
			//if (touches.length >= 2) {
			//touch = touches[1];
			//currentPos = touch.getLocation(this);
			//pathfinder.findPath(currentPos.x, currentPos.y, path);	
			//}
//}	
		}
		
//-----------------------------------------------------------------------------------------------------------------------------------------
		//in loop functions
		
		private function enterFrame(event:EnterFrameEvent):void
		{
			//Starling.current.juggler.advanceTime(event.passedTime);
			gameEnvironment.updatePhysics(event.passedTime);
			CONFIG::desktop
			{
				handleKeyboardInput();
			}
			moveCam();
			handleJoystickInput();
			CONFIG::debug
			{
				displayDebug();
			}
		}
		
		private function moveCam():void
		{
			this.pivotX = this.x - stage.stageWidth / 2;
			this.pivotY = this.y + stage.stageHeight / 2;
			this.rotation -= (this.rotation + player.body.rotation) - player.body.angularVel / 17;
			var v:Vec2 = player.body.velocity.copy(true).rotate(rotation).muleq(0.2);
			pointPool.setTo(player.body.position.x, player.body.position.y);
			this.localToGlobal(pointPool, pointPool);
			this.x -= pointPool.x - v.x - stage.stageWidth / 2;
			this.y -= pointPool.y - v.y - stage.stageHeight * 0.7;
			v.dispose();
			background.x = player.body.position.x - player.body.position.x % 512 - background.width / 2;
			background.y = player.body.position.y - player.body.position.y % 512 - background.height / 2;
			//obstacleTexture.x = player.body.position.x - player.body.position.x % 1024 - obstacleTexture.width / 2;
			//obstacleTexture.y = player.body.position.y - player.body.position.y % 1024 - obstacleTexture.height / 2;
			//updateImageOffset(background, backgroundRatio);
		}
		
		private function updateImageOffset(image:Image, ratio:Number):void
		{
			var xx:Number = ((player.body.position.x / image.width % 1) + 1);
			var yy:Number = ((player.body.position.y / image.height % 1) + 1);
			image.setTexCoords(0, xx, yy);
			image.setTexCoords(1, xx + ratio, yy);
			image.setTexCoords(2, xx, yy + ratio);
			image.setTexCoords(3, xx + ratio, yy + ratio);
		}
		
		CONFIG::debug private function displayDebug():void
		{
			napeDebug.clear();
			napeDebug.draw(Environment.physicsSpace);
			napeDebug.flush();
			napeDebug.transform = Mat23.fromMatrix(this.transformationMatrix);
			nevMeshView.drawEntity(enemy.pathfindingAgent, true);
			nevMeshView.drawEntity(player.pathfindingAgent, false);
			nevMeshView.drawPath(enemy.path);
			nevMeshView.drawMesh(Environment.navMesh);
			nevMeshView.surface.transform.matrix = this.transformationMatrix;
		}
		
		private function handleKeyboardInput():void
		{
			CONFIG::debug
			{
				CONFIG::air
				{
					if (Key.isDown(Keyboard.L))
					{
						lisDown = true;
					}
					else if (lisDown)
					{
						lisDown = false;
						var levelInfo:Level = new Level("level1");
						gameEnvironment.saveLevel(levelInfo);
					}
				}
			}
			if (Key.isDown(Keyboard.ENTER))
			{
				player.startShooting();
			}
			if (Key.isDown(Keyboard.W))
			{
				player.leftImpulse.y = player.rightImpulse.y = -player.maxAcceleration;
				if (Key.isDown(Keyboard.A))
				{
					player.leftImpulse.y -= player.maxAcceleration;
					player.rightImpulse.y += player.maxTurningAcceleration / 3;
				}
				else if (Key.isDown(Keyboard.D))
				{
					player.leftImpulse.y += player.maxTurningAcceleration / 3;
					player.rightImpulse.y -= player.maxAcceleration;
				}
			}
			else if (Key.isDown(Keyboard.S))
			{
				player.leftImpulse.y = player.rightImpulse.y = player.maxAcceleration;
				if (Key.isDown(Keyboard.A))
				{
					player.leftImpulse.y -= player.maxAcceleration;
					player.rightImpulse.y += player.maxTurningAcceleration / 3;
				}
				else if (Key.isDown(Keyboard.D))
				{
					player.leftImpulse.y += player.maxTurningAcceleration / 3;
					player.rightImpulse.y -= player.maxAcceleration;
				}
			}
			else if (Key.isDown(Keyboard.A))
			{
				player.leftImpulse.y -= player.maxAcceleration;
				player.rightImpulse.y += player.maxTurningAcceleration;
			}
			else if (Key.isDown(Keyboard.D))
			{
				player.leftImpulse.y += player.maxTurningAcceleration;
				player.rightImpulse.y -= player.maxAcceleration;
			}
		}
		
		private function handleJoystickInput():void
		{
			var joystickLocalPosition:Point = Pool.getPoint(0, 0);
			globalToLocal(joystickPosition, joystickLocalPosition);
			//joystick.x = pointPool.x;
			//joystick.y = pointPool.y;
			//joystick.rotation = -this.rotation;
			//	Pool.putPoint(joystickLocalPosition);
			if (mousePosition.length < joystickRadios + 70)
			{
				//joystickTranslation.invert();
				//joystick.transformQuad(1, joystickTranslation);
				//joystickTranslation.tx = 0;
				//joystickTranslation.ty = 0;
				//joystickTranslation.translate(mousePosition.x, mousePosition.y);
				//joystick.transformQuad(1, joystickTranslation);
				player.leftImpulse.y = player.maxTurningAcceleration * mousePosition.x / 160 + player.maxAcceleration * mousePosition.y / 160;
				player.rightImpulse.y = -player.maxTurningAcceleration * mousePosition.x / 160 + player.maxAcceleration * mousePosition.y / 160;
				player.stopShooting();
			}
			else
			{
				//if (!(joystickTranslation.tx == 0 && joystickTranslation.ty == 0))
				//{
				//joystickTranslation.invert();
				//joystick.transformQuad(1, joystickTranslation);
				//joystickTranslation.tx = 0;
				//joystickTranslation.ty = 0;
				//}
				if (ControllerInput.hasRemovedController())
				{
					if (ControllerInput.getRemovedController() == xboxController)
					{
						xboxController = null;
					}
				}
				if (xboxController)
				{
					if (xboxController.leftStick.distance > 0.1)
					{
						player.leftImpulse.y = xboxController.leftStick.x * player.maxTurningAcceleration * 1.2 - player.maxAcceleration * xboxController.leftStick.y;
						player.rightImpulse.y = -xboxController.leftStick.x * player.maxTurningAcceleration * 1.2 - player.maxAcceleration * xboxController.leftStick.y;
					}
					if (xboxController.rt.held)
					{
						player.startShooting();
					}
					else if (xboxController.rt.released)
					{
						player.stopShooting();
					}
				}
				else if (ControllerInput.hasReadyController())
				{
					xboxController = ControllerInput.getReadyController() as Xbox360Controller;
				}
			}
		}
	
	}
}