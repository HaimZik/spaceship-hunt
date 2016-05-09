package
{
	import com.input.Key;
	import com.spaceshiptHunt.entities.Player;
	import com.spaceshiptHunt.level.Environment;
	import flash.geom.Point;
	import flash.media.SoundChannel;
	import flash.media.SoundTransform;
	import flash.ui.Keyboard;
	import flash.utils.getTimer;
	import io.arkeus.ouya.ControllerInput;
	import io.arkeus.ouya.controller.Xbox360Controller;
	import nape.geom.Vec2;
	import starling.core.Starling;
	import starling.display.Image;
	import starling.display.Mesh;
	import starling.display.Sprite;
	import starling.events.*;
	import starling.geom.Polygon;
	import starling.rendering.VertexData;
	import starling.utils.Color;
	import starling.utils.Pool;
	CONFIG::debug
	{
		import com.spaceshiptHunt.level.LevelEditor;
	}
	
	/**
	 * ...
	 * @author Haim Shnitzer
	 */
	public class Game extends Sprite
	{
		
		private var joystickRadios:Number;
		private var joystick:Sprite;
		private var analogStick:Mesh;
		private var shootButton:Image;
		private var joystickPosition:Point;
		private var xboxController:Xbox360Controller;
		private var touches:Vector.<Touch> = new Vector.<Touch>();
		
		private var backgroundMusic:SoundChannel;
		private var volume:Number = 0.08;
		private var gameEnvironment:Environment;
		private var background:Image;
		private var player:Player;
		
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
				gameEnvironment = new LevelEditor(this);
			}
			CONFIG::release
			{
				gameEnvironment = new Environment(this);
			}
			Starling.current.start();
			gameEnvironment.enqueueLevel("Level1");
			drawJoystick();
			gameEnvironment.startLoading(onFinishLoadingInfo);
		}
		
		private function onFinishLoadingInfo():void
		{
			var atlaseNum:int = 1;
			for (var i:int = 0; i < atlaseNum; i++)
			{
				Environment.current.assetsLoader.enqueue("grp/textureAtlases" + i + ".xml");
				Environment.current.assetsLoader.enqueue("grp/textureAtlases" + i + ".atf");
			}
			Environment.current.assetsLoader.enqueue("grp/concrete_baked.atf");
			Environment.current.assetsLoader.enqueue("grp/concrete_baked_n.atf");
			gameEnvironment.startLoading(onFinishLoading);
		}
		
		private function onFinishLoading():void
		{
			shootButton = new Image(Environment.current.assetsLoader.getTexture("shootButton"));
			addChild(shootButton);
			shootButton.alignPivot();
			background = new Image(Environment.current.assetsLoader.getTexture("stars"));
			background.tileGrid = Pool.getRectangle();
			addChildAt(background, 0);
			var backgroundRatio:Number = Math.ceil(Math.sqrt(stage.stageHeight * stage.stageHeight + stage.stageWidth * stage.stageWidth) / 512) * 2;
			background.scale = backgroundRatio * 2;
			Key.init(stage);
			ControllerInput.initialize(Starling.current.nativeStage);
			player = Player.current;
			stage.addEventListener(KeyboardEvent.KEY_UP, keyUp);
			addEventListener(Event.ENTER_FRAME, enterFrame);
			addEventListener(TouchEvent.TOUCH, onTouch);
			Starling.current.stage.addEventListener(Event.RESIZE, stage_resize);
			Environment.current.assetsLoader.enqueueWithName("audio/Nihilore.mp3", "music");
			Environment.current.assetsLoader.loadQueue(function onProgress(ratio:Number):void
			{
				if (ratio == 1.0)
				{
					backgroundMusic = Environment.current.assetsLoader.getSound("music").play(0, 7);
					backgroundMusic.soundTransform = new SoundTransform(volume);
				}
			})
			addChild(Environment.current.light);
			this.setChildIndex(joystick, this.numChildren);
			//	PhysicsParticle.fill.cache();
		}
		
		private function keyUp(e:KeyboardEvent, keyCode:int):void
		{
			if (keyCode == Keyboard.ENTER)
			{
				player.stopShooting();
			}
			CONFIG::debug
			{
				CONFIG::air
				{
					if (keyCode == Keyboard.F1)
					{
						(gameEnvironment as LevelEditor).saveLevel();
					}
				}
			}
		}
		
		private function drawJoystick():void
		{
			joystick = new Sprite();
			joystickRadios = Math.min(500, Starling.current.stage.stageWidth, Starling.current.stage.stageHeight) / 4;
			var joystickShape:Polygon = Polygon.createCircle(0, 0, joystickRadios);
			joystickPosition = new Point(joystickRadios * 2 + 20, Starling.current.stage.stageHeight - 15);
			var vertices:VertexData = new VertexData(null, joystickShape.numVertices);
			joystickShape.copyToVertexData(vertices);
			var joystickBase:Mesh = new Mesh(vertices, joystickShape.triangulate());
			analogStick = new Mesh(vertices, joystickShape.triangulate());
			analogStick.alpha = joystickBase.alpha = 0.3;
			analogStick.color = joystickBase.color = Color.WHITE;
			joystick.x = joystickPosition.x;
			joystick.y = joystickPosition.y;
			joystick.addChild(joystickBase);
			analogStick.scale = 0.6;
			joystick.addChild(analogStick);
			addChild(joystick);
			joystick.pivotY = joystick.pivotX = joystickRadios;
		}
		
//-----------------------------------------------------------------------------------------------------------------------------------------
		//event functions	
		
		private function onTouch(e:TouchEvent):void
		{
			e.getTouches(this, null, touches);
			while (touches.length > 0)
			{
				var touch:Touch = touches.pop();
				if (touch.target.parent == joystick)
				{
					if (touch.phase == TouchPhase.MOVED || touch.phase == TouchPhase.BEGAN)
					{
						var position:Point = Pool.getPoint();
						touch.getLocation(joystick, position);
						if (position.length > joystickRadios * 1.2)
						{
							position.normalize(joystickRadios * 1.2);
						}
						analogStick.x = position.x;
						analogStick.y = position.y;
						Pool.putPoint(position);
					}
					else if (touch.phase == TouchPhase.ENDED)
					{
						analogStick.x = 0;
						analogStick.y = 0;
					}
				}
				else if (touch.target == shootButton)
				{
					if (touch.phase == TouchPhase.ENDED)
					{
						player.stopShooting();
					}
					else if (touch.phase == TouchPhase.BEGAN)
					{
						player.startShooting();
					}
				}
				else
				{
					CONFIG::debug
					{
						(gameEnvironment as LevelEditor).handleTouch(e);
					}
				}
			}
		}
		
		private function stage_resize(e:ResizeEvent = null):void
		{
			stage.stageWidth = e.width;
			stage.stageHeight = e.height;
			Starling.current.viewPort.width = e.width;
			Starling.current.viewPort.height = e.height;
			joystickRadios = int(Math.min(800, e.width, e.height) / 5);
			joystick.width = joystick.height = joystickRadios * 2;
			joystick.pivotX = joystick.pivotY = joystickRadios;
			joystickPosition.setTo(joystickRadios * 2 + 20, e.height - 15);
		}
		
//-----------------------------------------------------------------------------------------------------------------------------------------
		//runtime functions
		
		private function enterFrame(event:EnterFrameEvent):void
		{
			//Starling.current.juggler.advanceTime(event.passedTime);
			gameEnvironment.updatePhysics(event.passedTime);
			if(CONFIG::mobile==false)
			{
				handleKeyboardInput();
			}
			moveCam();
			handleJoystickInput();
		}
		
		private function moveCam():void
		{
			this.pivotX = this.x - stage.stageWidth / 2;
			this.pivotY = this.y + stage.stageHeight / 2;
			this.rotation -= (this.rotation + player.body.rotation) - player.body.angularVel / 17;
			var velocity:Vec2 = player.body.velocity.copy(true).rotate(rotation).muleq(0.2);
			var newScale:Number = 1 - velocity.length * velocity.length / 30000;
			this.scale += (newScale - this.scale) / 16;
			var poolPoint:Point = Pool.getPoint(player.body.position.x, player.body.position.y);
			this.localToGlobal(poolPoint, poolPoint);
			this.x -= poolPoint.x - velocity.x - stage.stageWidth / 2;
			this.y -= poolPoint.y - velocity.y - stage.stageHeight * 0.7;
			velocity.dispose();
			var parallaxRatio:Number = 0.5;
			background.x = player.body.position.x - (player.body.position.x * parallaxRatio) % 512 - background.width / 2;
			background.y = player.body.position.y - (player.body.position.y * parallaxRatio) % 512 - background.height / 2;
			
			this.globalToLocal(joystickPosition, poolPoint);
			joystick.x = poolPoint.x;
			joystick.y = poolPoint.y;
			joystick.scale = shootButton.scale = 1 / this.scale;
			joystick.rotation = shootButton.rotation = -this.rotation;
			poolPoint.copyFrom(joystickPosition);
			var shootIconWidth:Number = shootButton.texture.width;
			poolPoint.x += stage.stageWidth - joystickRadios * 2 - shootIconWidth / 2 - 30;
			poolPoint.y -= shootIconWidth / 2 - 5;
			this.globalToLocal(poolPoint, poolPoint);
			shootButton.x = poolPoint.x;
			shootButton.y = poolPoint.y;
			Pool.putPoint(poolPoint);
		}
		
		private function handleKeyboardInput():void
		{
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
			if (ControllerInput.hasRemovedController() && ControllerInput.getRemovedController() == xboxController)
			{
				xboxController = null;
			}
			if ((Math.abs(analogStick.x) + Math.abs(analogStick.y)) > 0)
			{
				var turningSpeed:Number = player.maxTurningAcceleration * Math.min(1, analogStick.x / 160);
				player.leftImpulse.y = player.rightImpulse.y = player.maxAcceleration * Math.min(1, analogStick.y / 160);
				player.leftImpulse.y += turningSpeed;
				player.rightImpulse.y -= turningSpeed
			}
			else if (xboxController)
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