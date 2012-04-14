package vn.ui {
	import flash.display.DisplayObjectContainer;
	import flash.display.Sprite;
	import flash.utils.Dictionary;
	/**
	 * ...
	 * @author thienhaflash
	 */
	public class KRadio {
		private var _view		: Sprite;
		private var _dictId		: Dictionary;
		private var _selectedId	: int;
		
		private var _items		: Array;
		private var _config		: Object;
		private var _activeId	: int;
		
		private var _onChange	: Function;
		
		public function KRadio(onChangeActive: Function = null) {
			_dictId = new Dictionary();
			_view = new Sprite();
			_onChange = onChangeActive;
		}
		
		public function active(idOrIndex: * ): void {
			var ri : RadioItem = _dictId[idOrIndex];
			if (!ri && idOrIndex is int) {
				ri = _items[idOrIndex as int];
			}
			if (ri) ri.active();
		}
		
		public function setConfig(config: Object): KRadio {
			_config = config;
			return this;
		}
		
		public function reset(parent: DisplayObjectContainer, ...rest): KRadio {
			var l		: int = rest.length;
			var item	: RadioItem;
			
			_items = [];
			var itm	: * ;
			var margin : int = 10;
			var px	: int = margin;
			for (var i: int = 0; i < l; i++) {
				itm = rest[i];
				item = new RadioItem(_api, i, itm);
				if (!(itm is String)) item.resetObject(itm);
				item.updateView(false);
				
				item.view.x = px;
				px += item.view.width + margin;
				view.addChild(item.view);
				_items.push(item);
			}
			
			parent.addChild(view);
			refresh();
			return this
		}
		
		public function refresh(force: Boolean = false):void { //refresh view - force will recreate items
			var ri : RadioItem;
			var l : int = _items.length;
			for (var i: int = 0; i < l; i++) {
				ri = _items[i];
				ri.updateView(i == _activeId);
			}
		}
		
		public function get view():Sprite { return _view; }
		
		public function get activeId():* {
			var ri: RadioItem = _items[_activeId];
			return ri.id != null ? ri.id : _activeId;
		}
		
	/******************
	 * 	INTERNAL API
	 *****************/
		
		private var _api		: Object = 
		{
			setId	: setId,
			active	: activeIndex 
		}
		
		private function setId(id: *, item: RadioItem): void {
			_dictId[id] = item;
		}
		
		private function activeIndex(index:int):void {
			var ri : RadioItem;
			if (_activeId != -1) {
				ri = _items[_activeId];
				ri.updateActive(false);
				//trace('unActive :: ', ri.index);
			}
			
			if (index != -1) {
				ri = _items[index];
				ri.updateActive(true);
				//trace('active :: ', ri.index);
			}
			
			_activeId = index;
			if (_onChange!= null && _activeId != -1) {
				_onChange(activeId); //pass the new activeId
			}
		}
	}
}
import flash.display.DisplayObject;
import flash.display.DisplayObjectContainer;
import flash.display.Graphics;
import flash.display.MovieClip;
import flash.display.Shape;
import flash.display.Sprite;
import flash.events.MouseEvent;
import flash.geom.ColorTransform;
import flash.text.TextField;
import flash.text.TextFieldAutoSize;
import flash.text.TextFormat;

class RadioItem {
	public var id		: * ;
	public var label	: String;
	public var index	: int;
	
	public var api		: Object; //KRadio api
	public var config	: Object; //config for this object
	public var view		: MovieClip;
	
	public function RadioItem(api: Object, index: int, label: String = null) {
		this.label		= label;
		this.index		= index;
		this.api		= api;
	}
	
	public function active(): void { api.active(this.index) }
	
	public function resetObject(obj: Object): void {
		if (obj.hasOwnProperty('id')) {
			id = obj.id;
			api.setId(obj.id, this);
		}
		if (obj.hasOwnProperty('label')) label = obj.label;
	}
	
	public function updateActive(isActive: Boolean): void {
		view.setActive(isActive);
	}
	
	public function updateView(isActive:Boolean): void {//force: Boolean
		view ||= new RadioItemMC();
		view.update(this);
		view.setActive(isActive);
	}
}

class RadioItemMC extends MovieClip {
	public var item		: RadioItem;
	public var tf		: TextField;
	public var radio	: Sprite;
	public var bg		: Shape;
	
	private var mcActive	: Shape;
	private var mcOver		: Shape;
	
	public function RadioItemMC() {
		bg		= Utils.newRect(0xD6d6d6, 'mcBg', this);
		tf		= Utils.newTextField('txtLabel', this);
		radio	= Utils.newRadio('mcRadio', this);
		
		this.mouseEnabled	= false;
		radio.buttonMode	= true;
		mcActive	= radio.getChildByName('mcActive') as Shape;
		mcOver		= radio.getChildByName('mcOver') as Shape;
		
		mcActive.visible	= false;
		mcOver.visible		= false;
		radio.mouseChildren = false;
		
		radio.x 	= 7;
		tf.x 		= 18;
		bg.alpha 	= 0;
		
		radio.addEventListener(MouseEvent.ROLL_OVER, _onOverRadio);
		radio.addEventListener(MouseEvent.ROLL_OUT, _onOutRadio);
		radio.addEventListener(MouseEvent.CLICK, _onClickRadio);
	}
	
	private function _onClickRadio(e:MouseEvent):void { item.active(); }
	private function _onOutRadio(e:MouseEvent):void { mcOver.visible = false; }
	private function _onOverRadio(e:MouseEvent):void { mcOver.visible = true; }
	
	public function setActive(value: Boolean): void {
		mcActive.visible = value;
		radio.mouseEnabled = !value;
	}
	
	public function update(data: RadioItem): void {
		item = data;
		
		tf.text		= data.label;
		bg.width	= tf.x + tf.width + 5;
		bg.height 	= tf.height;
		radio.y		= int(bg.height >> 1);
	}
	
	override public function get width():Number { return bg.width; }
	override public function get height():Number { return bg.height; }
}

class Utils {
	public static function newTextField(name: String, parent: DisplayObjectContainer): TextField {
		var tf : TextField = new TextField();
		
		var format : TextFormat = tf.defaultTextFormat;
		format.font = 'Arial';
		format.size = 12;
		
		tf.defaultTextFormat = format;
		tf.setTextFormat(format);
		
		tf.selectable = false;
		tf.autoSize = TextFieldAutoSize.LEFT;
		tf.mouseEnabled = false;
		tf.mouseWheelEnabled = false;
		tf.name = name;
		
		parent.addChild(tf);
		return tf;
	}
	
	public static function newRect(color: int, name: String, parent: DisplayObjectContainer): Shape {
		var shp : Shape = new Shape();
		var g	: Graphics = shp.graphics;
		
		g.beginFill(color);
		g.drawRect(0, 0, 100, 100);
		g.endFill();
		shp.name = name;
		
		parent.addChild(shp);
		return shp;
	}
	
	static public function removeChildren(holder:Sprite):void {
		while (holder.numChildren) holder.removeChildAt(0);
	}
	
	static public function newRadio(name:String, parent: DisplayObjectContainer):Sprite {
		var sprt	: Sprite	= new Sprite();
		var icon	: Shape 	= new Shape();
		var over	: Shape		= new Shape();
		var g		: Graphics	= sprt.graphics;
		
		g.lineStyle(1, 0x000000);
		g.beginFill(0xffffff);
		g.drawCircle(0, 0, 6);
		g.endFill();
		
		g = over.graphics;
		g.lineStyle(1, 0x55ff55);
		g.drawCircle(0, 0, 5);
		
		g = icon.graphics;
		g.beginFill(0x21A121);
		g.drawCircle(0, 0, 4);
		g.endFill();
		
		over.name = 'mcOver';
		sprt.addChild(over);
		
		icon.name = 'mcActive';
		sprt.addChild(icon);
		
		sprt.name = name;
		parent.addChild(sprt);
		return sprt;
	}
}