package  
{
	import flash.display.MovieClip;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import vn.ui.KGrid;
	/**
	 * ...
	 * @author thienhaflash
	 */
	public class KGridTest extends MovieClip {
		private var _grid : KGrid;
		
		public function KGridTest() {
			_grid = new KGrid({parent : this, x: 100, y: 100})
						.reset(100);
			stage.addEventListener(Event.ENTER_FRAME, _onMouseMove);
		}
		
		private function _onMouseMove(e:Event):void {
			_grid.position = stage.mouseY / stage.stageHeight;
		}
	}

}