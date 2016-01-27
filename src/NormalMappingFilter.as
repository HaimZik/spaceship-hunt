package
{
	import flash.display3D.Context3D;
	import flash.display3D.Context3DProgramType;
	import flash.display3D.Program3D;
	import flash.geom.Point;
	import starling.core.Starling;
	import starling.filters.FragmentFilter;
	import starling.textures.Texture;
 
	/**
	 * ...
	 * @author Frederico Garcia
	 */
	public class NormalMappingFilter extends FragmentFilter
	{
		private var _shaderProgram:Program3D;
		private var _normal:Texture;
		private var _pointLight:Point = new Point();
		private var _lightColorConstants:Vector.<Number> = new <Number>[0.5, 0.5, 0.5, 1];
		private var _lightPositionConstants:Vector.<Number> = new <Number>[0, 0, 10, 1];
 
		public function NormalMappingFilter(normal:Texture)
		{
			_normal = normal;
		}
 
		public override function dispose():void
		{
			if (_shaderProgram)
				_shaderProgram.dispose();
			super.dispose();
		}
 
		protected override function createPrograms():void
		{
			var fragmentShader:String =
				"tex ft0, v0, fs0 <2d,linear,nomip> \n" +
				"tex ft1, v0, fs1 <2d,linear,nomip> \n" +
				"mov ft2.x, fc1.w \n" +
				"add ft2.x, ft2.x, ft2.x \n" +
				"mul ft1, ft1, ft2.x \n" +
				"sub ft1, ft1, fc1.www \n" +
				"nrm ft1.xyz, ft1.xyz \n" +
				"mov ft2.z, ft1.w \n" +
				"sub ft2.xy, fc0.xy, v0.xy s\n" +
				"mov ft2.xy, fc0.xy \n" +
				"dp3 ft2.w, ft2.xyz, ft1.xyz \n" +
				"mul ft1.xyz, ft2.www, ft0.xyz \n" +
				"mul ft1.xyz, ft1.xyz, fc1.xyz \n" +
				"mov oc, ft1";
 
			_shaderProgram = assembleAgal(fragmentShader);
		}
 
		protected override function activate(pass:int, context:Context3D, texture:Texture):void
		{
			// update light point
			_lightPositionConstants[0] = _pointLight.x;
			_lightPositionConstants[1] = _pointLight.y;
 
			context.setProgramConstantsFromVector(Context3DProgramType.FRAGMENT, 1, _lightColorConstants);
			context.setProgramConstantsFromVector(Context3DProgramType.FRAGMENT, 0, _lightPositionConstants);
			context.setTextureAt(1, _normal.base);
			context.setProgram(_shaderProgram);
		}
 
		protected override function deactivate(pass:int, context:Context3D, texture:Texture):void
		{
			context.setTextureAt(1, null);
		}
 
		public function set pointLight(value:Point):void
		{
			_pointLight = value;
		}
 
		public function get pointLight():Point
		{
			return _pointLight;
		}
	}
}