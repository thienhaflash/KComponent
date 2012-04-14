package {
	import flash.display.MovieClip;
	import vn.ui.KRadio;
	/**
	 * ...
	 * @author thienhaflash
	 */
	public class KRadioTest extends MovieClip {
		private var _radioGroup : KRadio;
			
		public function KRadioTest() {
			new KRadio(trace).reset(this,
				{label: 'item 1', id: 'item1'}, 'item 2', 'item 3', 'item 4'
			)
		}
	}
}