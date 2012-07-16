package  
{
	import flash.display.MovieClip;
	import flash.display.StageScaleMode;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import vn.ui.KGrid;
	/**
	 * ...
	 * @author thienhaflash
	 */
	public class KGridTest extends MovieClip {
		private var _grid : KGrid;
		
		private var _tPos : Number;
		
		public function KGridTest() {
			_grid	= new KGrid(this)//, x: 100, y: 100
							.reset(1000);
			_tPos	= 0;
			
			stage.addEventListener(MouseEvent.MOUSE_DOWN, _updatePosition);
			stage.addEventListener(Event.ENTER_FRAME, _update);
			
			stage.scaleMode = StageScaleMode.NO_SCALE;
		}
		
		private var step : int;
		private function _updatePosition(e:Event):void {
			var d : int = 20;
			
			_tPos	= _grid.getRoundedPosition((stage.mouseY - d / 2) / (stage.stageHeight - d));
			_tPos = _tPos < 0 ? 0 : _tPos > 1 ? 1 : _tPos;
			step = 60;// 1 second
		}
		
		private function _update(e:Event):void {
			//Math.abs(_tPos - _grid.position) < 0.0001
			
			if (--step) {//1 / 1000 accuracy
				_grid.position	+= (_tPos - _grid.position)/5;
			} else {
				_grid.position = _tPos;
			}
		}
	}
}