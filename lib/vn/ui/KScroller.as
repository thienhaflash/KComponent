package vn.ui 
{
	import flash.display.DisplayObject;
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.text.TextField;
	
	/**
	 * ...
	 * @author thienhaflash
	 * 		1. Liquid size
	 * 		2. Adjustable delta / mousewheel / key on _view / disable relation / content size / pixel rounding
	 * 		3. Configurable skin : empty skin / default skin / offset enable
	 * 		4. Prebuild for common content cases : configurableMask, configurableText
	 * 		5. Update callbacks
	 * 		6. Bind to multiple content _view
	 * 		
	 * 		
	 */
	public class KScroller {
		private var _view:MovieClip;
		
		public var next:DisplayObject;
		public var prev:DisplayObject;
		public var track:DisplayObject;
		public var hand:DisplayObject;
		
		protected var _stDragPosition:Number;
		protected var _stDragMouseY:Number;
		
		protected var _relation:Number;
		protected var _position:Number;
		
		protected var _delta:Number; //number of pixels per MouseWheel
		
		protected var _slideL:Number;
		protected var update:Function;
		
		public function KScroller(parent: DisplayObjectContainer) {
			view = Utils.newScroller();
			delta = 0.1;
			//tp = 0;
			relation = 0.2;
			position = 0;
			
			parent.addChild(view);
		}
		
		private function _onClickPrev(e:MouseEvent):void {
			position -= delta;
		}
		
		private function _onClickNext(e:MouseEvent):void {
			position += delta;
		}
		
	/**********************
	 * 		PUBLIC API
	 **********************/
		
		private var _target: ScrollContent;
		
		public function setTarget(content: * , isHorz: Boolean, moveScroller: Boolean = true):KScroller {
			var tmpTarget : * = content is DisplayObject ? content : content.target;
			if (!tmpTarget) {
				trace('can not scroll a null target :: ', content);
				return this;
			}
			
			_target = tmpTarget is TextField 
						? new TextFieldContent(isHorz, tmpTarget)
						: new MaskedContent(isHorz).resetObject(content);
			
			if (moveScroller) {
				var pdo : DisplayObject = _target.content;
				if (isHorz) {
					view.x = pdo.x;
					view.rotation = 0;
					view.y = pdo.y + pdo.height + view.width+1;
					view.rotation = -90;
					setSize(pdo.width);
				} else {
					view.rotation = 0;
					view.x = pdo.x + pdo.width+1;
					view.y = pdo.y;
					setSize(pdo.height);
				}
				trace(_target.relation);
				relation = _target.relation;
			}
			
			return this;
		}
		
	/*************************
	 * 		DRAG HANDLING
	 ************************/
		
		private function _startDrag(e:MouseEvent):void {
			_stDragPosition = e.currentTarget == track ? _view.mouseY / track.height : _position;
			_stDragMouseY	= _view.mouseY;
			
			_view.addEventListener(Event.ENTER_FRAME, _updateDrag);
			_view.stage.addEventListener(MouseEvent.MOUSE_UP,		_stopDrag);
			_view.stage.addEventListener(Event.MOUSE_LEAVE,		_stopDrag);
		}
		
		private function _updateDrag(e: Event): void {
			var tVal:Number = (_view.mouseY - _stDragMouseY) / _slideL + _stDragPosition;
			position = tVal < 0 ? 0 : tVal > 1 ? 1 : tVal;
		}
		
		private function _stopDrag(e: Event): void {
			_view.removeEventListener(Event.ENTER_FRAME, _updateDrag);
			_view.stage.removeEventListener(MouseEvent.MOUSE_UP,		_stopDrag);
			_view.stage.removeEventListener(Event.MOUSE_LEAVE,			_stopDrag);
		}
		
	/*************************
	 * 		DRAG HANDLING
	 ************************/	
		
		public function setSize(size:int):void {
			track.height = size;
			relation = _relation;
		}
		
		/*private function updatePosition(e:Event):void {
			var delta:Number = (tp - _position) / 1;
			
			if (_position + delta == _position) { //Don't change anymore
				position = tp;
				_view.removeEventListener(Event.ENTER_FRAME, updatePosition);
			} else {
				position = _position + delta;
			}
		}*/
		
		private function onMouseWheel(e:MouseEvent):void {
			var tVal:Number = _position - e.delta * _delta / 3;
			position = tVal < 0 ? 0 : tVal > 1 ? 1 : tVal;
			//_view.addEventListener(Event.ENTER_FRAME, updatePosition);
		}
		
		public function get relation():Number { return _relation; }
		public function set relation(value:Number):void {
			_relation = value;
			_view.visible = !(_relation <= 0 || _relation >= 1);
			
			if (_view.visible) {
				hand.height = Math.max(20, Math.round((track.height-(prev? prev.height+next.height: 0)) * _relation));
				_slideL = track.height - hand.height;
				//if (next && prev) {
					//_slideL -= next.height + prev.height;
				//}
			}
		}
		
		public function get position():Number { return _position; }
		public function set position(value:Number):void {
			_position = value < 0 ? 0 : value > 1 ? 1 : value;
			hand.y = track.y + int(_slideL * _position);// + (prev ? prev.height : 0);
			
			if (_target) _target.setPosition(_position);
			if (update != null) update(_position);
		}
		
		public function get delta():Number { return _delta; }
		public function set delta(value:Number):void { _delta = value; }
		
		/*public function set immediatePosition(value:Number):void {
			_position = value < 0 ? 0 : value > 1 ? 1 : value;
			hand.y = int(_slideL * _position) + (prev ? prev.height : 0);
			
			if (_target) _target.setPosition(_position);
			if (update != null) update(_position);
		}*/
		
		public function get view():MovieClip  { return _view; }
		public function set view(value:MovieClip):void {
			//TODO : remove old view ?
			
			_view = value;
			
			track	= _view.mcTrack;
			hand	= _view.mcHand;
			next	= _view.getChildByName('mcNext');
			prev	= _view.getChildByName('mcPrev');
			
			track.addEventListener(MouseEvent.MOUSE_DOWN, _startDrag);
			hand.addEventListener(MouseEvent.MOUSE_DOWN, _startDrag);
			
			if (hand is Sprite) (hand as Sprite).buttonMode = true;
			if (_view.stage) {
				_addMouseWheel(null);
			} else {
				_view.addEventListener(Event.ADDED_TO_STAGE, _addMouseWheel);
			}
			
			if (next) next.addEventListener(MouseEvent.CLICK, _onClickNext);
			if (prev) prev.addEventListener(MouseEvent.CLICK, _onClickPrev);
			
		}
		
		private function _addMouseWheel(e:Event):void {
			if (e) _view.removeEventListener(Event.ADDED_TO_STAGE, _addMouseWheel);
			_view.parent.addEventListener(MouseEvent.MOUSE_WHEEL, onMouseWheel);
		}
	}
}

import flash.display.DisplayObject;
import flash.geom.Rectangle;
import flash.text.TextField;

class ScrollContent {
	public var isHorz	: Boolean;
	public var content	: DisplayObject;
	
	public function setPosition(pct: Number): void { }
	public function resetObject(obj: Object): * { return this; }
	public function get relation(): Number { return 0.25; }
}

class TextFieldContent extends ScrollContent {
	public var target	: TextField;
	
	public function TextFieldContent(isHorz : Boolean, tf: TextField) {
		this.isHorz = isHorz;
		target = tf;
		content = tf;
		//TODO : listen to text change ?
	}
	
	override public function setPosition(pct:Number):void {
		var scrollValue : * = (isHorz ?	target.maxScrollH : target.maxScrollV) * pct;
		//trace(target.maxScrollH, scrollValue, pct*target.maxScrollH);
		isHorz ? target.scrollH = scrollValue : target.scrollV = scrollValue;
	}
}

class MaskedContent extends ScrollContent {
	public var target		: DisplayObject;
	public var mask			: DisplayObject;
	
	public var align	: int;
	public var margin	: int; //top / bottom
	public var maskRect	: Rectangle;
	public var config	: Object;
	
	public function MaskedContent(isHorz : Boolean) {
		this.isHorz = isHorz;
	}
	
	override public function resetObject(obj:Object):* {
		if (obj is DisplayObject) {
			target	= obj as DisplayObject;
			mask	= target.mask;
			
			if (!mask) {
				trace('mask target ', obj, ' did not have a mask, at least you need to input the mask size');
				return;
			}
		} else {
			//TODO : support callbacks
			//contentW, contentH
			config = obj;
			target = obj.target;
			if (!target) trace('can not create mask for a null scrolling target');
			
			if (obj.hasOwnProperty('mask')) {
				if (obj.mask is DisplayObject) {//use the specified mask
					mask 		= target.mask = obj.mask;
				} else {//create a mask
					mask = Utils.newRect(0, 'mcMask', null);
					target.mask = mask;
					
					margin		= obj.mask.margin ? obj.mask.margin : 0;
					maskRect	= new Rectangle(
						obj.mask.x ? obj.mask.x : target.x,
						obj.mask.y ? obj.mask.y : target.y,
						obj.mask.width ? obj.mask.width : target.width,
						obj.mask.height ? obj.mask.height : target.height
					)
					
					mask.x		= maskRect.x - margin;
					mask.y 		= maskRect.y - margin;
					mask.width	= maskRect.width + 2 * margin;
					mask.height	= maskRect.height + 2 * margin;
				}
			} else { //get the mask from the target
				mask = target.mask;
			}
		}
		
		if (!maskRect) {
			margin		= isHorz ? target.x - mask.x : target.y - mask.y;
			maskRect	= new Rectangle(
				mask.x + margin,
				mask.y + margin,
				mask.width - 2 * margin,
				mask.height -2 * margin
			)
		}
		
		content = mask;
		//default : align top + center horizontally
		align = obj.hasOwnProperty('align') ? obj.align : isHorz ? 1 : 0;
		return this;
	}
	
	override public function setPosition(pct:Number):void {//read empty align property (align top, left, center or ?
		var isEmpty : Boolean = isHorz ? (target.width < maskRect + margin) : (target.height < maskRect.height + margin);
		
		if (isHorz) {
			isEmpty ? Utils.alignX(target, maskRect, align) : target.x = maskRect.x + pct * (maskRect.width - target.width);
		} else {
			isEmpty ? Utils.alignY(target, maskRect, align) : target.y = maskRect.y + pct * (maskRect.height - target.height);
		}
		
		//trace(isEmpty, pct, maskRect.height, target.height, pct * (maskRect.height - target.height), target.x);
	}
	
	override public function get relation():Number {
		return Math.max(0, isHorz ? (maskRect.width/target.width) : (maskRect.height/target.height));
	}
}

import flash.display.DisplayObjectContainer;
import flash.display.Graphics;
import flash.display.MovieClip;
import flash.display.Shape;
import flash.display.Sprite;

class Utils {
	public static function newRect(color: int, name: String, parent: DisplayObjectContainer): Shape {
		var shp : Shape = new Shape();
		var g	: Graphics = shp.graphics;
		
		g.beginFill(color);
		g.drawRect(0, 0, 100, 100);
		g.endFill();
		shp.name = name;
		if (parent) parent.addChild(shp);
		
		return shp;
	}
	
	public static function newSprite(color: int, name: String, parent: DisplayObjectContainer): Sprite {
		var sprt : Sprite = new Sprite();
		var g	: Graphics = sprt.graphics;
		
		g.beginFill(color);
		g.drawRect(0, 0, 100, 100);
		g.endFill();
		sprt.name = name;
		parent.addChild(sprt);
		
		return sprt;
	}
	
	public static function newScroller(): MovieClip {
		var mc		: MovieClip = new MovieClip();
		var mcTrack : Sprite	= newSprite(0xD6D6D6, 'mcTrack', mc);
		var mcHand	: Sprite	= newSprite(0x666666, 'mcHand', mc);
		
		mcTrack.height = 200;
		mcTrack.width = 10;
		mcHand.width = 10;
		
		mc.mcTrack = mcTrack;
		mc.mcHand = mcHand;
		return mc;
	}
	
	public static function alignX(target: DisplayObject, to : Object, mode: int): void {
		switch (mode) {
			case 0 : target.x = to.x;break;//left;
			case 1 : target.x = to.x + (to.width - target.width) / 2;break;
			case 2 : target.x = to.x + (to.width - target.width);break;
		}
	}
	
	public static function alignY(target: DisplayObject, to : Object, mode: int): void {
		switch (mode) {
			case 0 : target.y = to.y;break;//left;
			case 1 : target.y = to.y + (to.height - target.height) / 2;break;
			case 2 : target.y = to.y + (to.height - target.height);break;
		}
	}
}


