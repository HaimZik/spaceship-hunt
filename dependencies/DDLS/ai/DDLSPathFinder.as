package DDLS.ai
{
	import DDLS.data.DDLSEdge;
	import DDLS.data.DDLSFace;
	import DDLS.data.DDLSMesh;
	import DDLS.data.math.DDLSGeom2D;
	
	public class DDLSPathFinder
	{
		public var physicsHitTestLine:Function;
		private var _mesh:DDLSMesh;
		private var _astar:DDLSAStar;
		private var _funnel:DDLSFunnel;
		private var _entity:DDLSEntityAI;
		private var _radius:Number;
		
		private var __listFaces:Vector.<DDLSFace>;
		private var __listEdges:Vector.<DDLSEdge>;
		
		public function DDLSPathFinder()
		{
			_astar = new DDLSAStar();
			_funnel = new DDLSFunnel();
			
			__listFaces = new Vector.<DDLSFace>();
			__listEdges = new Vector.<DDLSEdge>();
		}
		
		public function dispose():void
		{
			_mesh = null;
			_astar.dispose();
			_astar = null;
			_funnel.dispose();
			_funnel = null;
			__listEdges = null;
			__listFaces = null;
		}
		
		public function get entity():DDLSEntityAI
		{
			return _entity;
		}
		
		public function set entity(value:DDLSEntityAI):void
		{
			_entity = value;
		}
		
		public function get mesh():DDLSMesh
		{
			return _mesh;
		}
		
		public function set mesh(value:DDLSMesh):void
		{
			_mesh = value;
			_astar.mesh = _mesh;
		}
		
		public function findPath(toX:Number, toY:Number, resultPath:Vector.<Number>):void
		{
			if (!_mesh)
				throw new Error("Mesh missing");
			if (!_entity)
			{
				throw new Error("Entity missing");
			}
			resultPath.length = 0;
			_astar.radius = _entity.radius;
			_funnel.radius = _entity.radius;
			__listFaces.length = 0;
			__listEdges.length = 0;
			if (DDLSGeom2D.isCircleIntersectingAnyConstraint(toX, toY, _entity.radius, _mesh))
			{
				return;
			}
			var constraintCircleRadius:Number = 25; //32
			var approximateObjectRadius:Number = _entity.radius + constraintCircleRadius;
			var directionX:Number = _entity.dirNormX * approximateObjectRadius * 2.1;
			var directionY:Number = _entity.dirNormY * approximateObjectRadius * 2.1;
			if (!tryFindPath(directionX, directionY, toX, toY, resultPath))//forward
			{
				if (!tryFindPath(directionY, -directionX, toX, toY, resultPath))//right
				{
					if (!tryFindPath(-directionY, directionX, toX, toY, resultPath))//left
					{
						tryFindPath(-directionX, -directionY, toX, toY, resultPath)//behind
					}
				}
			}
		}
		
		private function tryFindPath(directionX:Number, directionY:Number, toX:Number, toY:Number, resultPath:Vector.<Number>):Boolean
		{
			if (!isPathBlocked(directionX, directionY))
			{
				_astar.findPath(_entity.x + directionX, _entity.y + directionY, toX, toY, __listFaces, __listEdges);
				if (__listFaces.length != 0)
				{
					_funnel.findPath(_entity.x + directionX, _entity.y + directionY, toX, toY, __listFaces, __listEdges, resultPath);
					return true;
				}
			}
			return false;
		}
		
		private function isPathBlocked(directionX:Number, directionY:Number):Boolean
		{
			return DDLSGeom2D.isCircleIntersectingAnyConstraint(_entity.x + directionX, _entity.x + directionY, _entity.radius, _mesh);
		}
	
	}
}