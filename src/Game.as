package
{
	import com.input.Key;
	import com.spaceshipStudent.EnemyAI;
	import com.spaceshipStudent.Level;
	import com.spaceshipStudent.Environment;
	import com.spaceshipStudent.Player;
	import flash.geom.Matrix;
	import flash.geom.Point;
	import flash.media.SoundChannel;
	import flash.media.SoundTransform;
	import io.arkeus.ouya.controller.Xbox360Controller;
	import io.arkeus.ouya.ControllerInput;
	import nape.geom.Vec2;
	import nape.phys.Body;
	import nape.phys.BodyType;
	import starling.core.Starling;
	import starling.display.Canvas;
	import starling.display.Image;
	import starling.display.QuadBatch;
	import starling.display.Sprite;
	import starling.events.Event;
	import starling.events.ResizeEvent;
	import starling.events.Touch;
	import starling.events.TouchEvent;
	import starling.events.TouchPhase;
	import starling.textures.RenderTexture;
	import starling.textures.TextureOptions;
	import starling.utils.Color;
	CONFIG::debug
	{
		import com.spaceshipStudent.EnvironmentBuilder;
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
		private var joystick:QuadBatch;
		private var joystickTranslation:Matrix = new Matrix();
		private var joystickPosition:Point;
		private var xboxController:Xbox360Controller;
		private var background:Image;
		private var backgroundRatio:Number;
		private var obstacleTexture:Image;
		private var backgroundMusic:SoundChannel;
		private var pointPool:Point = new Point();
		private var touches:Vector.<Touch> = new Vector.<Touch>();
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
			joystick = new QuadBatch();
			drawJoystick();
			Starling.current.start();
			Starling.current.stop();
			player = new Player(new Vec2(5200, 4720));
			gameEnvironment.enemy = new EnemyAI(new Vec2(4900, 4700), player);
			gameEnvironment.player = this.player;
			gameEnvironment.enqueueBody("player", player.body, addChild(new Sprite()));
			gameEnvironment.enqueueBody("batship", gameEnvironment.enemy.body, addChild(new Sprite()));
			gameEnvironment.enqueueBody("level1", new Body(BodyType.STATIC), obstacleMask);
			gameEnvironment.loadLevel(onFinishLoadingInfo);
		}
		
		private function onFinishLoadingInfo():void
		{
			gameEnvironment.assetsLoader.enqueue("grp/textureAtlases.xml");
			gameEnvironment.assetsLoader.enqueue("grp/textureAtlases.png");
			gameEnvironment.assetsLoader.enqueueWithName("grp/stars.png", "stars", new TextureOptions(1.0, false, "bgra", true));
			gameEnvironment.assetsLoader.enqueueWithName("grp/concrete_baked.png", "concrete", new TextureOptions(1.0, false, "bgra", true));
			gameEnvironment.loadLevel(onFinishLoading);
		}
		
		private function onFinishLoading():void
		{
			background = new Image(gameEnvironment.assetsLoader.getTexture("stars"));
			obstacleTexture = new Image(gameEnvironment.assetsLoader.getTexture("concrete"));
			addChildAt(background, 0);
			addChildAt(obstacleTexture, 1);
			backgroundRatio = Math.ceil(Math.sqrt(stage.stageHeight * stage.stageHeight + stage.stageWidth * stage.stageWidth) / 512) * 2;
			background.scaleX = background.scaleY = backgroundRatio;
			obstacleTexture.scaleX = obstacleTexture.scaleY = backgroundRatio;
			updateImageOffset(obstacleTexture, backgroundRatio);
			obstacleTexture.mask = obstacleMask;
			mousePosition = new Point(stage.stageWidth, 0);
			this.setChildIndex(joystick, numChildren);
			player.gunType = "fireCannon";
			Starling.current.start();
			Key.init(Starling.current.nativeStage);
			ControllerInput.initialize(Starling.current.nativeStage);
			addEventListener(Event.ENTER_FRAME, enterFrame);
			addEventListener(TouchEvent.TOUCH, onTouch);
			Starling.current.stage.addEventListener(Event.RESIZE, stage_resize);
			gameEnvironment.assetsLoader.enqueueWithName("audio/Nihilore.mp3", "music");
			gameEnvironment.assetsLoader.loadQueue(function onProgress(ratio:Number):void
			{
				if (ratio == 1.0)
				{
					backgroundMusic = gameEnvironment.assetsLoader.getSound("music").play(0, 7);
					backgroundMusic.soundTransform = new SoundTransform(0.4);
				}
			})
		}
		
		private function drawJoystick():void
		{
			joystickRadios = Math.min(600, Starling.current.stage.stageWidth, Starling.current.stage.stageHeight) / 4;
			var joyShape:Canvas = new Canvas();
			joyShape.beginFill(Color.GRAY, 0.3);
			joyShape.drawCircle(joystickRadios, joystickRadios, joystickRadios);
			joyShape.endFill();
			joystickPosition = new Point(joystickRadios + 20, Starling.current.stage.stageHeight - joystickRadios - 10);
			var joystickTexture:RenderTexture = new RenderTexture(joystickRadios * 2, joystickRadios * 2);
			joystickTexture.draw(joyShape);
			joyShape.dispose();
			var joystickImage:Image = new Image(joystickTexture);
			joystick.pivotY = joystick.pivotX = joystickRadios;
			joystick.x = joystickPosition.x;
			joystick.y = joystickPosition.y;
			joystick.addImage(joystickImage);
			addChild(joystick);
			joystickImage.pivotY = joystickImage.pivotX = joystickRadios;
			joystickImage.y = joystickImage.x = joystickRadios;
			joystickImage.scaleY = joystickImage.scaleX = 0.7;
			joystick.addImage(joystickImage);
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
			joystick.rotation = 0;
			joystick.x = joystick.y = 0;
			joystick.width = joystick.height = joystickRadios * 2;
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
				}
				else
				{
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
		
		private function enterFrame():void
		{
			gameEnvironment.updatePhysics();
			handleKeyboardInput();
			handleJoystickInput();
			moveCam();
			CONFIG::debug
			{
				//displayDebug();
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
			handleJoystickInput();
			background.x = player.body.position.x - player.body.position.x % 512 - background.width / 2;
			background.y = player.body.position.y - player.body.position.y % 512 - background.height / 2;
			obstacleTexture.x = player.body.position.x - player.body.position.x % 1024 - obstacleTexture.width / 2;
			obstacleTexture.y = player.body.position.y - player.body.position.y % 1024 - obstacleTexture.height / 2;
			updateImageOffset(background, backgroundRatio);
		}
		
		private function updateImageOffset(image:Image, ratio:Number):void
		{
			var xx:Number = ((player.body.position.x / image.width % 1) + 1);
			var yy:Number = ((player.body.position.y / image.height % 1) + 1);
			image.setTexCoordsTo(0, xx, yy);
			image.setTexCoordsTo(1, xx + ratio, yy);
			image.setTexCoordsTo(2, xx, yy + ratio);
			image.setTexCoordsTo(3, xx + ratio, yy + ratio);
		}
		
		CONFIG::debug private function displayDebug():void
		{
			//napeDebug.clear();
			//napeDebug.draw(levelManger.physicsSpace);
			//napeDebug.flush();
			//napeDebug.transform = Mat23.fromMatrix(this.transformationMatrix);
			nevMeshView.drawEntity(gameEnvironment.enemy.entityAI, true);
			nevMeshView.drawEntity(player.entityAI, false);
			//nevMeshView.drawPath(batship.path);
			nevMeshView.drawMesh(gameEnvironment.navMesh);
			nevMeshView.surface.transform.matrix = this.transformationMatrix;
		}
		
		private function handleKeyboardInput():void
		{
			CONFIG::debug
			{
				CONFIG::air
				{
					if (Key.lIsDown)
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
			if (Key.wIsDown)
			{
				player.leftImpulse.y = player.rightImpulse.y = -player.maxAcceleration;
				if (Key.aIsDown)
				{
					player.leftImpulse.y -= player.maxAcceleration;
					player.rightImpulse.y += player.maxTurningAcceleration / 3;
				}
				else if (Key.dIsDown)
				{
					player.leftImpulse.y += player.maxTurningAcceleration / 3;
					player.rightImpulse.y -= player.maxAcceleration;
				}
			}
			else if (Key.sIsDown)
			{
				player.leftImpulse.y = player.rightImpulse.y = player.maxAcceleration;
				if (Key.aIsDown)
				{
					player.leftImpulse.y -= player.maxAcceleration;
					player.rightImpulse.y += player.maxTurningAcceleration / 3;
				}
				else if (Key.dIsDown)
				{
					player.leftImpulse.y += player.maxTurningAcceleration / 3;
					player.rightImpulse.y -= player.maxAcceleration;
				}
			}
			else if (Key.aIsDown)
			{
				player.leftImpulse.y -= player.maxAcceleration;
				player.rightImpulse.y += player.maxTurningAcceleration;
			}
			else if (Key.dIsDown)
			{
				player.leftImpulse.y += player.maxTurningAcceleration;
				player.rightImpulse.y -= player.maxAcceleration;
			}
		}
		
		private function handleJoystickInput():void
		{
			globalToLocal(joystickPosition, pointPool);
			joystick.x = pointPool.x;
			joystick.y = pointPool.y;
			joystick.rotation = -this.rotation;
			if (mousePosition.length < joystickRadios + 70)
			{
				joystickTranslation.invert();
				joystick.transformQuad(1, joystickTranslation);
				joystickTranslation.tx = 0;
				joystickTranslation.ty = 0;
				joystickTranslation.translate(mousePosition.x, mousePosition.y);
				joystick.transformQuad(1, joystickTranslation);
				player.leftImpulse.y = player.maxTurningAcceleration * mousePosition.x / 160 + player.maxAcceleration * mousePosition.y / 160;
				player.rightImpulse.y = -player.maxTurningAcceleration * mousePosition.x / 160 + player.maxAcceleration * mousePosition.y / 160;
			}
			else
			{
				if (!(joystickTranslation.tx == 0 && joystickTranslation.ty == 0))
				{
					joystickTranslation.invert();
					joystick.transformQuad(1, joystickTranslation);
					joystickTranslation.tx = 0;
					joystickTranslation.ty = 0;
				}
				if (ControllerInput.hasRemovedController())
				{
					if (ControllerInput.getRemovedController() == xboxController)
					{
						xboxController = null;
					}
				}
				if (xboxController && xboxController.leftStick.distance > 0.1)
				{
					player.leftImpulse.y = xboxController.leftStick.x * player.maxTurningAcceleration * 1.2 - player.maxAcceleration * xboxController.leftStick.y;
					player.rightImpulse.y = -xboxController.leftStick.x * player.maxTurningAcceleration * 1.2 - player.maxAcceleration * xboxController.leftStick.y;
				}
				else
				{
					if (ControllerInput.hasReadyController())
					{
						xboxController = ControllerInput.getReadyController() as Xbox360Controller;
					}
				}
			}
		}
	
	}
}