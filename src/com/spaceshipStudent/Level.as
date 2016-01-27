package com.spaceshipStudent 
{
	/**
	 * ...
	 * @author Haim Shnitzer
	 */
	public class Level 
	{
		private var _name:String;
		public function Level(levelName:String) 
		{
			_name = levelName;
		}
		
		public function get name():String 
		{
			return _name;
		}
		
	}

}