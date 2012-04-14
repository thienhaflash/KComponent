package  
{
	import flash.display.Graphics;
	import flash.display.MovieClip;
	import flash.display.Shape;
	import flash.events.TextEvent;
	import flash.text.TextField;
	import vn.ui.KScroller;
	/**
	 * ...
	 * @author thienhaflash
	 */
	public class KScrollerTest extends MovieClip {
		private var scroller	: KScroller;
		private var tf			: TextField;
		
		public function KScrollerTest() {
			tf = new TextField();
			var s : String;
			for (var i: int = 0; i < 1000; i++) {
				s += 'line :: '+ i + 'linelinelinelinelinelinelinelinelinelineline\n';
			}
			
			tf.textColor = 0;
			tf.text = s;
			tf.border = true;
			addChild(tf);
			new KScroller(this).setTarget(tf, true);
			new KScroller(this).setTarget(tf, false);
			
			var mc : Shape = new Shape();
			var g: Graphics = mc.graphics;
			for (i = 0; i < 100; i++) {
				g.lineStyle(i % 5, Math.random() * 0xffffff);
				g.lineTo(Math.random() * 400, Math.random() * 1000)
			}
			addChild(mc);
			mc.x = mc.y = 100;
			new KScroller(this).setTarget( { target: mc, mask: { width : 200, height :200 }}, true);
			new KScroller(this).setTarget( { target: mc, mask: { width : 200, height: 200 }}, false);
		}
	}
}