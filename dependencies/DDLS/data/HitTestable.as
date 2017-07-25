package DDLS.data
{
	import DDLS.ai.DDLSEntityAI;
	
	/**
	 * ...
	 * @author Haim Shnitzer
	 */
	public interface HitTestable  
	{		
	   function hitTestLine(fromEntity:DDLSEntityAI, directionX:Number, directionY:Number):Boolean;	
	}
	
}