package vn.ui {
	
	import flash.display.DisplayObject;
	import flash.display.MovieClip;
	import flash.display.Shape;
	import flash.display.Sprite;
	import flash.utils.Dictionary;
	import flash.utils.getDefinitionByName;
	import flash.utils.getQualifiedClassName;
	
	/**
	 * ...
	 * @author
	 */
	public class KGrid {
		/** EXTERNAL DATA **/
		private var _data:*;
		private var _dataLength:int;
		
		/** CALL_BACKS **/
		public var onUpdate:Function; //call to update both content / position
		public var onContent:Function; //calls to update separatedly
		public var onPosition:Function;
		//public var onResize		: Function;
		
		//private var _targetDO:MovieClip;
		private var _view : Sprite;
		private var _holder:Sprite;
		private var _mask:Shape;
		
		/** INTERNAL DATA **/
		private var _config:KConfig;
		//private var _autoPosition	: Boolean; //automatically position items
		
		private var _width:int;
		private var _height:int;
		
		private var _first:int; //first item to be render
		private var _last:int; //last item to be render
		private var _nItems:int; //nRows * nCols
		private var _items:Array;
		
		private var _activeIdx		: int;
		
		public function KGrid(parentOrViewProps: *, onContent:Function = null) { //, autoConfig: Boolean = true
			_view = new Sprite();
			_holder	= new Sprite();
			_view.addChild(_holder);
			_mask	= Utils.newMask(_holder, 100, 100);
			if (parentOrViewProps) Utils.setView(parentOrViewProps, _view);
			
			_items	= [];
			_config = new KConfig({
				maskX : 0,
				maskY : 0,
				maskMrg : 1,
				maskW : 100,
				maskH : 200,
				
				contentMrg : 1,
				contentOff: 0,
				
				isHorz: false,
				cellW : 100,
				cellH : 20,
				nRows : 10,
				nCols : 1
			});
			
			_nItems = 11;
			//_position = 0;
			setSampleClass(TextItem);
			Utils.resizeArray(_items, _sampleClass, _nItems);
			
			updateMaskSize();
			this.onContent = onContent;
		}
		
		private var _sample			: DisplayObject;
		private var _sampleClass	: Class;
		
		public function setSample(pdo: Object): KGrid {
			_sampleClass = getDefinitionByName(getQualifiedClassName(pdo)) as Class;
			_holder.x		= _sample.x;
			_holder.y		= _sample.y;
			_config.maskX	= _holder.x;
			_config.maskY	= _holder.y;
			
			_config.cellW = _sample.width;
			_config.cellH = _sample.height;
			return this;
		}
		
		public function setSampleClass(cls : Class): KGrid {
			_sampleClass = cls;
			_sample = new _sampleClass();
			_config.cellW = _sample.width;
			_config.cellH = _sample.height;
			return this;
		}
		
	/*************************
	 * 	INIT / CONFIGURATION
	 *************************/
		
		public function setDimension(nRows:int, nCols:int, isHorz:Boolean):KGrid {
			_config.nRows = nRows;
			_config.nCols = nCols;
			_config.isHorz = isHorz;
			
			if (_config.maskW == 0 && _config.maskH == 0) {
				_config.maskW = (isHorz ? _config.nCols - 1 : _config.nCols) * _config.cellW;
				_config.maskH = (isHorz ? _config.nRows : (_config.nRows - 1)) * _config.cellH;
				updateMaskSize();
			}
			
			Utils.resizeArray(_items, _sampleClass, nRows * nCols);
			_nItems = _items.length;
			
			calculateWH();
			refreshPosition();
			return this;
		}
		
		public function setPadding(pxStart:int, pxEnd:int):KGrid {
			_config.contentOff = pxStart;
			_config.contentMrg = pxEnd;
			return this;
		}
		
		public function setCell(w:int, h:int):KGrid {
			_config.cellW = w;
			_config.cellH = h;
			calculateWH();
			refreshPosition();
			return this;
		}
		
		public function setMaskSize(w:int, h:int, margin:int):KGrid {
			_config.maskW = w;
			_config.maskH = h;
			_config.maskMrg = margin;
			
			updateMaskSize();
			return this;
		}
		
		public function getDelta(n:int = 1):Number {
			var px:int = (_config.isHorz ? _config.cellW : _config.cellH) * n;
			return Math.max(0, _config.isHorz ? px / (_width - _config.maskW) : (px / (_height - _config.maskH)));
		}
		
		public function setActivateScrollAt(n:int):KGrid {
			_config.activeScrollAt = n;
			return this;
		}
		
		/**
		 * call on change cellW / cellH / nRows / nCols
		 * item positions will be refresh
		 * @param	objectOrXML the config data (support XML / Object)
		 */ /*public function config(objectOrXML: *): KGrid {
		   objectOrXML is XML ? _config.resetXML(objectOrXML) :_config.resetObject(objectOrXML);
		
		   //_total		= Math.ceil(_config.isHorz ? _dataLength / _config.nCols : _dataLength / _config.nRows);
		
		   return this;
		 }*/
		
		/****************
		 * 		API
		 ***************/
		
		/**
		 * call on data source change, content will automatically refresh
		 * item positions will be reset to the beginning
		 *
		 * @param	data array of item datas
		 * @return
		 */
		public function reset(data:*, resetPosition:Boolean = true):KGrid {
			_data = data;
			_dataLength = data is XMLList ? data.length() : data.length;
			_activeIdx = -1;
			
			first = 0;
			Utils.removeChildren(_holder);
			var min:int = Math.min(_dataLength, _nItems);
			
			for (var i:int = 0; i < min; i++) {
				_holder.addChild(_items[i]);
			}
			
			calculateWH();
			refreshContent();
			refreshPosition();
			
			if (resetPosition) position = 0;
			
			return this;
		}
		
		public function refreshContent():void {
			if (!_data)
				return;
			
			if (onContent == null) {
				//trace(this, ' WARNING : no .onUpdate(idx, mc, data) attached so item content wont be updated to new data');
			} else {
				updateItems(-1, _nItems, false, onContent);
			}
		}
		
		public function refreshPosition():void {
			if (!_data) return;
			//force update
			updateItems(-1, _nItems, true, onPosition);
		}
		
		private var _position:Number;
		
		public function set position(value:Number):void {
			value = isNaN(value) || value < 0 ? 0 : value > 1 ? 1 : value;
			_position = value;
			
			if (_config.isHorz) {
				_holder.x = Math.round(_config.maskX + _config.maskMrg + (_config.maskW >= _width ? _config.centerShortContent ? (_config.maskW - _width) / 2 : 0 : (_config.maskW - _width) * value)) + _config.contentOff;
				
				first = _config.maskW > _width ? 0 : int((_config.maskX - _holder.x) / _config.cellW) * _config.nRows;
			} else {
				_holder.y = Math.round(_config.maskY + _config.maskMrg + (_config.maskH >= _height ? _config.centerShortContent ? (_config.maskH - _height) / 2 : 0 : (_config.maskH - _height) * value)) + _config.contentOff;
				first = _config.maskH > _height ? 0 : int((_config.maskY - _holder.y) / _config.cellH) * _config.nCols;
			}
			
			//update content, then update positions
			updateItems(_dFrom, _dCount, false, onContent);
			updateItems(_dFrom, _dCount, true, onPosition);
		}
		
		/******************
		 * 		GETTERS
		 ******************/
		
		public function get height():int {
			return _height;
		}
		
		public function get width():int {
			return _width;
		}
		
		public function get relation():Number {
			if (!_data || (_dataLength <= _config.activeScrollAt))
				return 1;
			return _config.isHorz ? (_config.maskW / _width) : (_config.maskH / _height);
		}
		
		public function get position():Number {
			if (!_data) return 0;
			
			//trace(_config.maskW, _width, _config.maskH, _height);
			return isNaN(_position) ? _config.isHorz ? (_config.maskW >= _width) ? 0 : ((_config.maskX + _config.maskMrg - _holder.x + _config.contentOff) / (_width - _config.maskW)) : (_config.maskH >= _height) ? 0 : ((_config.maskY + _config.maskMrg - _holder.y + _config.contentOff) / (_height - _config.maskH)) : _position;
		}
		
		/****************
		 * 	INTERNAL
		 ***************/
		
		private var _dFrom:int;
		private var _dCount:int;
		
		private function set first(value:int):void {
			//crop <value> to range [0, _dataLength]
			value = value < 0 ? 0 : value > _dataLength - _nItems ? Math.max(0, _dataLength - _nItems) : value;
			
			if (_first != value) { //there are changes
				_dFrom = value > _first ? _last + 1 : value;
				_dCount = Math.abs(value - _first);
				
				_first = value;
				_last = Math.min(_first + _nItems - 1, _dataLength - 1);
				
				if (_dCount >= _nItems) { //optimized :: update maximum nItems
					_dFrom = -1;
					_dCount = _nItems;
				}
			} else { //nothing to update
				_last = Math.min(_first + _nItems - 1, _dataLength - 1);
				
				_dFrom = 0;
				_dCount = 0;
			}
		}
		
		private function updateItems(from:int, nUpdate:int, isPosition:Boolean, func:Function):void {
			if (from < _first)
				from = _first;
				
			var to:int = Math.min(from + nUpdate, _last + 1);
			var offset:int = from - int(from / _nItems) * _nItems;
			var mc:Object;
			
			for (var i:int = from; i < to; i++) {
				mc = _items[(offset + i - from) % _nItems];
				
				if (isPosition /* && _autoPosition*/) {
					if (_config.isHorz) {
						mc.x = int(i / _config.nRows) * _config.cellW;
						mc.y = (i % _config.nRows) * _config.cellH;
					} else {
						mc.x = (i % _config.nCols) * _config.cellW;
						mc.y = int(i / _config.nCols) * _config.cellH;
					}
					if (mc.hasOwnProperty('onPosition')) mc.onPosition(this, i, _data[i]);
				} else {
					if (mc.hasOwnProperty('onContent')) mc.onContent(this, i, _data[i]);
				}
				
				if (func != null) func(i, mc, _data[i]);
			}
		}
		
		public function get activeIdx():int {
			return _activeIdx;
		}
		
		public function set activeIdx(value:int):void {
			var oldIdx : int = _activeIdx;
			_activeIdx = value;
			
			//refresh both old and new item
			if (oldIdx != -1) updateItems(oldIdx, 1, false, onContent);
			if (value != -1) updateItems(value, 1, false, onContent);
		}
		
		public function get activeMc():MovieClip {
			if (_activeIdx == -1 || _activeIdx < _first || _activeIdx > _last)
				return null;
			return _items[_activeIdx % _nItems];
		}
		
		public function get activeData():* {
			return _activeIdx == -1 ? null : _data[_activeIdx];
		}
		
		public function get view():Sprite {
			return _view;
		}
		
		private function calculateWH():void {
			if (!_data)
				return;
			
			if (_config.isHorz) {
				_width = Math.ceil(_dataLength / _config.nRows) * _config.cellW + _config.contentMrg + _config.contentOff;
				_height = _config.nRows * _config.cellH;
			} else {
				_width = _config.nCols * _config.cellW;
				_height = Math.ceil(_dataLength / _config.nCols) * _config.cellH + _config.contentMrg + _config.contentOff;
			}
		}
		
		private function updateMaskSize():void {
			_mask.width = _config.maskW;
			_mask.height = _config.maskH;
		}
	
	}
}
import flash.display.MovieClip;
import flash.display.Shape;
import flash.display.Sprite;
import flash.events.MouseEvent;
import flash.text.TextField;
import flash.text.TextFieldAutoSize;
import flash.text.TextFormat;
import flash.utils.flash_proxy;
import flash.utils.Proxy;

class TextItem extends MovieClip {
	public var tf	: TextField;
	public var over : Shape;
	public var bg	: Shape;
	
	private var id		: int;
	private var grid	: Object;
	
	public function TextItem() {
		bg		= Utils.newRect(0xEEEEEE, 'mcBg', this);
		over	= Utils.newRect(0x8888ff, 'mcOver', this);
		tf		= Utils.newTextField('txtLabel', this);
		
		over.height = 20;
		bg.height = 20;
		
		over.visible = false;
		mouseChildren = false;
		
		buttonMode = true;
		addEventListener(MouseEvent.MOUSE_OVER, _showOver);
		addEventListener(MouseEvent.MOUSE_OUT, _hideOver);
		addEventListener(MouseEvent.CLICK, _onClickItem);
	}
	
	private function _onClickItem(e:MouseEvent):void {
		grid.activeIdx = id;
	}
	
	private function _hideOver(e:MouseEvent):void {
		if (grid.activeIdx != id) over.visible = false;
	}
	
	private function _showOver(e:MouseEvent):void {
		if (grid.activeIdx != id) over.visible = true;
	}
	
	override public function get width():Number { return bg.width; }
	override public function get height():Number { return bg.height; }
	
	public function onContent(grid: Object, id: int, data : * ): void {
		//trace('onContent ::', id);
		tf.text = 'TextItem : ' + id;
		bg.alpha = id % 2 ? 1 : 0.5;
		
		over.visible	= grid.activeIdx == id; //always show if active !
		buttonMode		= !over.visible;
		
		this.id		= id;
		this.grid	= grid;
	}
}

import flash.display.DisplayObject;
import flash.display.DisplayObjectContainer;
import flash.display.Graphics;
import flash.display.Shape;
import flash.utils.getDefinitionByName;
import flash.utils.getQualifiedClassName;

/*class GridConfig {
   public var nRows	: int;
   public var nCols	: int;
   public var isHorz	: Boolean;

   public var cellW	: int;
   public var cellH	: int;

   public var contentOff	: int; //offset the _holder content
   public var contentMrg	: int;

   public var maskX	: int;
   public var maskY	: int;
   public var maskW	: int;
   public var maskH	: int;
   public var maskMrg	: int; //margin for better content read

   public var activeScrollAt		: int;
   public var centerShortContent	: Boolean; //centerize short content ?

   //private var _dirtyN	: Boolean; //check if nRows*nCols changed
   //private var _dirtyP	: Boolean; //check if cellW / cellH / margin change

   public function GridConfig() { }

   public function resetObject(obj: Object): void {
   if (obj) Utils.copyObj(obj, this);
   }

   public function resetXML(xml: XML):void {
   //TODO : fill in
   }

   public function reset(nRows: int, nCols: int, isHorz: Boolean, margin: int = 0, cellW: int = 0, cellH: int = 0): void {
   this.nRows	= nRows;
   this.nCols	= nCols;
   this.isHorz	= isHorz;
   if (cellW>0) this.cellW	= cellW;
   if (cellH>0) this.cellH	= cellH;
   this.maskMrg = margin;
   }

 }*/

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
	
	/*public static function setSample(pdo:Object):void {
		sample = pdo;
		sampleClass = getDefinitionByName(getQualifiedClassName(pdo)) as Class;
		if (pdo.parent)
			pdo.parent.removeChild(pdo);
	}*/
	
	public static function newMask(pdo:DisplayObject, w:int, h:int):Shape {
		var shp:Shape = new Shape();
		var g:Graphics = shp.graphics;
		g.beginFill(0, 0.5);
		g.drawRect(0, 0, 100, 100);
		g.endFill();
		
		if (pdo.parent)
			pdo.parent.addChild(shp);
		
		shp.x = pdo.x;
		shp.y = pdo.y;
		shp.width = w;
		shp.height = h;
		pdo.mask = shp;
		return shp;
	}
	
	public static function copyObj(src:Object, tar:Object = null):void {
		for (var s: String in src) {
			tar[s] = src[s];
		}
	}
	
	/**
	 * remove all children from a DisplayObjectContainer
	 * @param	targetDOC should be DisplayObjectContainer, declared as Object to minimal type casting
	 */
	public static function removeChildren(targetDOC:Object):void {
		var doc:DisplayObjectContainer = targetDOC as DisplayObjectContainer;
		if (doc) {
			while (doc.numChildren > 0) {
				doc.removeChildAt(0); //FIXME : there may sometimes security error on this : catch later
			}
		} else {
			trace('removeChildren fail on ', targetDOC);
		}
	}
	
	public static function resizeArray(arr:Array, sampleClass: Class, n:int):Array {
		if (!arr)
			arr = [];
		
		for (var i:int = arr.length; i < n; i++) { //add more items if needed
			arr.push(new sampleClass());
		}
		return arr;
	}
	
	public static function setView(parentOrViewProps:Object, view:DisplayObject):void {
		if (parentOrViewProps is DisplayObjectContainer) {
			parentOrViewProps.addChild(view);
		} else {
			var p:DisplayObjectContainer = parentOrViewProps.parent;
			if (p) p.addChild(view);
			for (var s:String in parentOrViewProps) {
				try {
					view[s] = parentOrViewProps[s];
				} catch (e:Error) {}
			}
		}
	}
}

dynamic class KConfig extends Proxy {
	protected var _config	: Object;
	protected var _default	: Object;
	
	public function KConfig(defaultConfig: Object) {
		_default	= defaultConfig;
		_config		= { };
	}
	
	public function reset(obj: Object): KConfig {
		_config = obj;
		return this;
	}
	
	override flash_proxy function getProperty(name:*):* {
		return _config.hasOwnProperty(name) ? _config[name] : _default[name];
	}
	
	override flash_proxy function setProperty(name:*, value:*):void {
		_config[name] = value;
	}
	
	override flash_proxy function hasProperty(name:*):Boolean {
		return _config.hasOwnProperty(name);
	}
}