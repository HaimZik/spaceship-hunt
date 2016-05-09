package DDLS.data.math
{

	public class DDLSPoint2D
	{
		
		public var x:Number;
		public var y:Number;
		
		public function DDLSPoint2D(x:Number=0, y:Number=0)
		{
			this.x = x;
			this.y = y;
		}
		
		public function transform(matrix:DDLSMatrix2D):void
		{
			matrix.tranform(this);
		}
		
		public function set(x:Number, y:Number):void
		{
			this.x = x;
			this.y = y;
		}
		
		public function clone():DDLSPoint2D
		{
			return new DDLSPoint2D(x, y);
		}
		
		public function substract(p:DDLSPoint2D):void
		{
			x -= p.x;
			y -= p.y;
		}
		
		public function get length():Number
		{
			return Math.sqrt(x*x + y*y);
		}
		
		public function normalize():void
		{
			var norm:Number = length;
			x = x/norm;
			y = y/norm;
		}
		
		public function scale(s:Number):void
		{
			x = x*s;
			y = y*s;
		}
		
		public function distanceTo(p:DDLSPoint2D):Number
		{
			var diffX:Number = x - p.x;
			var diffY:Number = y - p.y;
			return Math.sqrt(diffX*diffX + diffY*diffY);
		}

	}
}