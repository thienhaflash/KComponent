package {
	import flash.display.MovieClip;
	import vn.ui.KInput;
	/**
	 * ...
	 * @author ...
	 */
	public class KInputTest extends MovieClip {
		
		public function KInputTest() {
			new KInput(this).setHint('hello, input something here !');
		}
	}
}