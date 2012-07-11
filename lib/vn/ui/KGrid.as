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
		private var _hasData	: Boolean;
		private var _data		: *;
		private var _dataLength	: int;
		
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
			
			_config = new KConfig({
				maskX : 0,
				maskY : 0,
				maskMrg : 1,
				maskW : 200,
				maskH : 200,
				
				contentMrg : 1,
				contentOff: 0,
				
				isHorz: false,
				cellW : 100,
				cellH : 20,
				nRows : 10,
				nCols : 2
			});
			
			//setClipping(false, false);
			setSample(new TextItem());
			_sampleClass = TextItem;
			
			updateMaskSize();
			this.onContent = onContent;
		}
		
		private var _sample			: DisplayObject;
		private var _sampleClass	: Class;
		
		public function setSample(pdo: Object): KGrid {
			try {
				_sampleClass	= getDefinitionByName(getQualifiedClassName(pdo)) as Class;
			} catch (e: Error) { trace('Can not find definition <' + getQualifiedClassName(pdo) + '>') }
			
			_sample			= pdo as DisplayObject;
			_holder.x		= _sample.x;
			_holder.y		= _sample.y;
			_config.maskX	= _holder.x;
			_config.maskY	= _holder.y;
			_config.cellW	= _sample.width;
			_config.cellH	= _sample.height;
			
			if (_sample.parent) _sample.parent.removeChild(_sample);
			checkMaskSize();
			
			//_items = [pdo];
			//_nItems = 1;
			
			_items = [];
			_nItems = 0;
			
			//Utils.resizeArray(_items, _sampleClass, _nItems);
			return this;
		}
		
		//public function setSampleClass(cls : Class): KGrid {
			//_sampleClass = cls;
			//setSample(new cls());
			//_sampleClass = cls;
			//_sample = new _sampleClass();
			//_config.cellW = _sample.width;
			//_config.cellH = _sample.height;
			//
			//_items = [];
			//_nItems = 0;
			//Utils.resizeArray(_items, _sampleClass, _nItems);
			//return this;
		//}
		
	/*************************
	 * 	INIT / CONFIGURATION
	 *************************/
		
		public function setClipping(useAlpha: Boolean, useMask : Boolean): KGrid {
			_config.useAlpha = useAlpha;
			_config.useMask = useMask;
			
			if (!useMask) {
				_holder.mask = null;
				_mask.visible = false;
			} else {
				_holder.mask = _mask;
				_mask.visible = true;
			}
			
			return this;
		}
		
		private function checkMaskSize(): void {
			if (_config.nCols > 0 && _config.nRows > 0 && _config.cellW && _config.cellH) {
				_config.maskW = (_config.isHorz ? _config.nCols - 1 : _config.nCols) * _config.cellW;
				_config.maskH = (_config.isHorz ? _config.nRows : (_config.nRows - 1)) * _config.cellH;
				updateMaskSize();
			}
		}
		
		public function setDimension(nRows:int, nCols:int, isHorz:Boolean):KGrid {
			_config.nRows = nRows;
			_config.nCols = nCols;
			_config.isHorz = isHorz;
			
			checkMaskSize();
			
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
		
		public function setMaskSize(w:int, h:int, margin:int = 0):KGrid {
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
		 * @param	data array / XMLList of item datas or length
		 * @return
		 */
		public function reset(data:*, resetPosition:Boolean = true):KGrid {
			_hasData = !(data is int);
			_data = _hasData ? data : [];
			_dataLength = _hasData ? data is XMLList ? data.length() : data.length : data as int;
			_activeIdx = -1;
			
			_nItems = _config.nCols * _config.nRows + (_config.isHorz ? _config.nRows : _config.nCols)
			Utils.resizeArray(_items, _sampleClass, _nItems);
			
			var min:int = Math.min(_dataLength, _nItems);
			Utils.removeChildren(_holder);
			for (var i:int = 0; i < min; i++) {
				_holder.addChild(_items[i]);
			}
			
			_mask.x	= _holder.x = _config.maskX;
			_mask.y = _holder.y = _config.maskY;
			
			first = 0;
			
			calculateWH();
			refreshContent();
			refreshPosition();
			
			if (resetPosition) position = 0;
			return this;
		}
		
		public function refreshContent():void {
			updateItems(-1, _nItems, false, onContent);
		}
		
		public function refreshPosition():void {
			updateItems(-1, _nItems, true, onPosition);
		}
		
		private var _position:Number;
		
		public function set position(value:Number):void {
			value = isNaN(value) || value < 0 ? 0 : value > 1 ? 1 : value;
			_position = value;
			
			var d1		: int;
			var d2		: int;
			var i		: int;
			var mc		: DisplayObject;
			
			var maskX	: int = _config.maskX;
			var maskY	: int = _config.maskY;
			var maskW	: int = _config.maskW;
			var maskH	: int = _config.maskH;
			var maskMrg : int = _config.maskMrg;
			
			var cellW	: int = _config.cellW;
			var cellH	: int = _config.cellH;
			var nRows	: int = _config.nRows;
			
			//trace('setPosition ::', maskX, maskY, maskW, maskH, maskMrg, cellW, cellH, nRows );
			//TODO : Optimize so we only check alpha for last + new boundary items
			
			if (_config.isHorz) {
				_holder.x	= Math.round(maskX + maskMrg + (maskW >= _width ? _config.centerShortContent ? (maskW - _width) / 2 : 0 : (maskW - _width) * value)) + _config.contentOff;
				first		= maskW > _width ? 0 : int((maskX - _holder.x) / cellW) * nRows;
				
				//update content, then update positions
				updateItems(_dFrom, _dCount, false, onContent);
				updateItems(_dFrom, _dCount, true, onPosition);
			
				if (_config.useAlpha) {
					d1 		= maskX - _holder.x;
					d2		= d1 + maskW - cellW;
					
					for (i = 0; i < _nItems; i++) {
						mc			=	_items[i];
						mc.alpha	=	mc.x < d1 	? Math.max(0, 1 - (d1 - mc.x) / cellW) : 
										mc.x > d2	? Math.max(0, 1 - (mc.x - d2) / cellW) : 1;
					}
				}
			} else {
				_holder.y = Math.round(maskY + _config.maskMrg + (maskH >= _height ? _config.centerShortContent ? (maskH - _height) / 2 : 0 : (maskH - _height) * value)) + _config.contentOff;
				first = maskH > _height ? 0 : int((maskY - _holder.y) / cellH) * _config.nCols;
				
				//update content, then update positions
				updateItems(_dFrom, _dCount, false, onContent);
				updateItems(_dFrom, _dCount, true, onPosition);
				
				if (_config.useAlpha) {
					d1			= maskY - _holder.y;
					d2			= d1 + maskH - cellH;
					
					for (i = 0; i < _nItems; i++) {
						mc			= 	_items[i];
						mc.alpha	=	mc.y < d1 ? Math.max(0, 1 - (d1 - mc.y) / cellH) : 
										mc.y > d2 ? Math.max(0, 1 - (mc.y - d2) / cellH) : 1;
					}
				}
			}
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
			if (_dataLength <= _config.activeScrollAt) return 1;
			return _config.isHorz ? (_config.maskW / _width) : (_config.maskH / _height);
		}
		
		public function get position():Number {
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
			if (from < _first) from = _first;
			
			var to:int = Math.min(from + nUpdate, _last + 1);
			var offset:int = from - int(from / _nItems) * _nItems;
			var mc:Object;
			
			if (from < to) trace('update', to-from, 'items : ', from,'-', to);//, _first, _last, nUpdate, isPosition
			
			for (var i:int = from; i < to; i++) {
				mc = _items[(offset + i - from) % _nItems];
				
				//trace(i, mc, mc.onContent);
				if (isPosition /* && _autoPosition*/) {
					if (_config.isHorz) {
						mc.x = int(i / _config.nRows) * _config.cellW;
						mc.y = (i % _config.nRows) * _config.cellH;
					} else {
						mc.x = (i % _config.nCols) * _config.cellW;
						mc.y = int(i / _config.nCols) * _config.cellH;
					}
					if (mc.hasOwnProperty('onPosition')) mc.onPosition(this, i, _hasData ? _data[i] : i);
				} else {
					if (mc.hasOwnProperty('onContent')) mc.onContent(this, i, _hasData ? _data[i] : i);
				}
				
				if (func != null) func(i, mc, _hasData ? _data[i] : i);
			}
		}
		
		public function get activeIdx():int {
			return _activeIdx;
		}
		
		public function set activeIdx(value:int):void {
			var oldIdx	: int		= _activeIdx;
			var mc		: MovieClip = activeMc;
			
			_activeIdx = value;
			
			//refresh both old and new item
			if (oldIdx != -1 && mc) (mc.hasOwnProperty('setActive')) ? mc.setActive(false) : updateItems(oldIdx, 1, false, onContent);
			
			mc = activeMc;
			if (value != -1 && mc) (mc.hasOwnProperty('setActive')) ? mc.setActive(true) : updateItems(value, 1, false, onContent);
		}
		
		public function get activeMc():MovieClip {
			if (_activeIdx == -1 || _activeIdx < _first || _activeIdx > _last) return null;
			return _items[_activeIdx % _nItems];
		}
		
		public function get activeData():* {
			return _activeIdx == -1 ? null : _hasData ? _data[_activeIdx] : _activeIdx;
		}
		
		public function get view():Sprite {
			return _view;
		}
		
		private function calculateWH():void {
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
import flash.utils.getTimer;
import flash.utils.Proxy;
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

 //class gItem {
	 //public var isSelected	: Boolean;
	 //public var userData	: Object; //any data
//}

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
		//pdo.mask = shp;
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
		tf.text		= id + "|"+getTimer();
		bg.alpha	= ((id % 4) == 0 || (id % 4) == 3) ? 1 : 0.5;
		
		setActive(grid.activeIdx == id);
		
		this.id		= id;
		this.grid	= grid;
	}
	
	public function setActive(isActive: Boolean): void {
		over.visible	= isActive; //always show if active !
		over.alpha 		= isActive ? 1 : 0.5;
		buttonMode		= !isActive;
	}
}