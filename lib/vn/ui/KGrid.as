package vn.ui {
	
	import flash.display.DisplayObject;
	import flash.display.MovieClip;
	import flash.display.Shape;
	import flash.display.Sprite;
	import flash.geom.Rectangle;
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
		//public var onUpdate:Function; //call to update both content / position
		//public var onContent:Function; //calls to update separatedly
		//public var onPosition:Function;
		//public var onResize		: Function;
		
		//private var _targetDO:MovieClip;
		private var _view : Sprite;
		private var _holder:Sprite;
		private var _mask:Shape;
		
		/** INTERNAL DATA **/
		private var _config	: gConfig;
		//private var _autoPosition	: Boolean; //automatically position items
		
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
			
			_config = new gConfig();
			
			var sample : DisplayObject = parentOrViewProps ? Utils.setView(parentOrViewProps, _view) : null;
			sample	? setSample(sample) : setSampleClass(TextItem);
			
			updateMaskSize();
			_config.onContent = onContent;
		}
		
	/**************************
	 * 		DEBUGGER
	 *************************/
		
		public var logLevel	: int;
		public var logger	: Function;
		
		private function log(funcName: String, message: String, level : int = 0): void {
			if (level > logLevel) return;
			
			//format message 
			var s : String = 'KGrid.' + funcName + '() fail - ' + message;
			(logger != null) ? logger(s) : trace(s);
		}
		
	/**************************
	 * 	SAMPLE / INSTANTIATE
	 *************************/
		
		
		
	/*************************
	 * 	INIT / CONFIGURATION
	 *************************/
		
		public function setClipping(useAlphaClip: Boolean, useMaskClip : Boolean): KGrid {
			_config.useAlphaClip = useAlphaClip;
			_config.useMaskClip = useMaskClip;
			
			if (!useMaskClip) {
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
				_config.viewW = (_config.isHorz ? _config.nCols - 1 : _config.nCols) * _config.cellW;
				_config.viewH = (_config.isHorz ? _config.nRows : (_config.nRows - 1)) * _config.cellH;
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
			_config.paddingStart = pxStart;
			_config.paddingEnd = pxEnd;
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
			_config.viewW = w;
			_config.viewH = h;
			_config.maskMrg = margin;
			
			updateMaskSize();
			return this;
		}
		
		public function getDelta(n:int = 1):Number {
			var px:int = (_config.isHorz ? _config.cellW : _config.cellH) * n;
			return Math.max(0, _config.isHorz ? px / (_config.width - _config.viewW) : (px / (_config.height - _config.viewH)));
		}
		
		public function setActivateScrollAt(n:int):KGrid {
			//_config.activeScrollAt = n;
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
			
			_mask.x	= _holder.x = _config.x;
			_mask.y = _holder.y = _config.y;
			
			first = 0;
			
			calculateWH();
			refreshContent();
			refreshPosition();
			
			if (resetPosition) position = 0;
			return this;
		}
		
		public function refreshContent():void {
			updateItems(-1, _nItems, false, _config.onContent);
		}
		
		public function refreshPosition():void {
			updateItems(-1, _nItems, true, _config.onPosition);
		}
		
		private var _position:Number;
		
		public function set position(value:Number):void {
			value = isNaN(value) || value < 0 ? 0 : value > 1 ? 1 : value;
			_position = value;
			
			var d1		: int;
			var d2		: int;
			var i		: int;
			var mc		: DisplayObject;
			
			var x	: int = _config.x;
			var y	: int = _config.y;
			var viewW	: int = _config.viewW;
			var viewH	: int = _config.viewH;
			var maskMrg : int = _config.maskMrg;
			
			var cellW	: int = _config.cellW;
			var cellH	: int = _config.cellH;
			var nRows	: int = _config.nRows;
			
			//trace('setPosition ::', x, y, viewW, viewH, maskMrg, cellW, cellH, nRows );
			//TODO : Optimize so we only check alpha for last + new boundary items
			
			if (_config.isHorz) {
				_holder.x	= Math.round(x + maskMrg + (viewW >= _config.width ? _config.centerShortContent ? (viewW - _config.width) / 2 : 0 : (viewW - _config.width) * value)) + _config.paddingStart;
				first		= viewW > _config.width ? 0 : int((x - _holder.x) / cellW) * nRows;
				
				//update content, then update positions
				updateItems(_dFrom, _dCount, false, _config.onContent);
				updateItems(_dFrom, _dCount, true, _config.onPosition);
			
				if (_config.useAlphaClip) {
					d1 		= x - _holder.x;
					d2		= d1 + viewW - cellW;
					
					for (i = 0; i < _nItems; i++) {
						mc			=	_items[i];
						mc.alpha	=	mc.x < d1 	? Math.max(0, 1 - (d1 - mc.x) / cellW) : 
										mc.x > d2	? Math.max(0, 1 - (mc.x - d2) / cellW) : 1;
					}
				}
			} else {
				_holder.y = Math.round(y + _config.maskMrg + (viewH >= _config.height ? _config.centerShortContent ? (viewH - _config.height) / 2 : 0 : (viewH - _config.height) * value)) + _config.paddingStart;
				first = viewH > _config.height ? 0 : int((y - _holder.y) / cellH) * _config.nCols;
				
				//update content, then update positions
				updateItems(_dFrom, _dCount, false, _config.onContent);
				updateItems(_dFrom, _dCount, true, _config.onPosition);
				
				if (_config.useAlphaClip) {
					d1			= y - _holder.y;
					d2			= d1 + viewH - cellH;
					
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
			return _config.height;
		}
		
		public function get width():int {
			return _config.width;
		}
		
		public function get relation():Number {
			//TODO : fix me if (_dataLength <= _config.activeScrollAt) return 1;
			return _config.isHorz ? (_config.viewW / _config.width) : (_config.viewH / _config.height);
		}
		
		public function get position():Number {
			return isNaN(_position) ? _config.isHorz ? (_config.viewW >= _config.width) ? 0 : ((_config.x + _config.maskMrg - _holder.x + _config.paddingStart) / (_config.width - _config.viewW)) : (_config.viewH >= _config.height) ? 0 : ((_config.y + _config.maskMrg - _holder.y + _config.paddingStart) / (_config.height - _config.viewH)) : _position;
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
		
	/***********************
	 * 		CELL INFO
	 **********************/
		
		public function getRow(idx : int) : int {
			return _config.isHorz ? int(idx / _config.nRows) : (idx % _config.nCols);
		}
		
		public function getCol(idx: int) : int {
			return _config.isHorz ? (idx % _config.nRows) : int(idx / _config.nCols);
		}
		
		public function getViewPercent(idx: int): Number {
			return 
		}
		
		
		
		
		
		
		public function getCellInfo(idx: int): Object {
			var row : int = _config.isHorz ? int(i / _config.nRows) : (i % _config.nCols);
			var col : int = _config.isHorz ? (i % _config.nRows) : int(i / _config.nCols);
			
			var d1	: int = isHorz ? x - _holder.x :  y - _holder.y;
			var d2	: int = isHorz ? d1 + viewW - cellW	: d1 + viewH - cellH;
			
			return {
				row 		: row,
				col 		: col,
				x 			: row * _config.cellW,
				y 			: row * _config.cellH,
				
			}
		}
		
		public function get activeIdx():int { return _activeIdx; }
		
		public function set activeIdx(value:int):void {
			var oldIdx	: int		= _activeIdx;
			var mc		: MovieClip = activeMc;
			
			_activeIdx = value;
			
			//refresh both old and new item
			if (oldIdx != -1 && mc) (mc.hasOwnProperty('setActive')) ? mc.setActive(false) : updateItems(oldIdx, 1, false, _config.onContent);
			
			mc = activeMc;
			if (value != -1 && mc) (mc.hasOwnProperty('setActive')) ? mc.setActive(true) : updateItems(value, 1, false, _config.onContent);
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
				_config.width = Math.ceil(_dataLength / _config.nRows) * _config.cellW + _config.paddingEnd + _config.paddingStart;
				_config.height = _config.nRows * _config.cellH;
			} else {
				_config.width = _config.nCols * _config.cellW;
				_config.height = Math.ceil(_dataLength / _config.nCols) * _config.cellH + _config.paddingEnd + _config.paddingStart;
			}
		}
		
		private function updateMaskSize():void {
			_mask.width = _config.viewW;
			_mask.height = _config.viewH;
		}
	}
}

import flash.display.BitmapData;
import flash.display.MovieClip;
import flash.display.Shape;
import flash.display.Sprite;
import flash.events.MouseEvent;
import flash.geom.Rectangle;
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

   public var paddingStart	: int; //offset the _holder content
   public var paddingEnd	: int;

   public var x	: int;
   public var y	: int;
   public var viewW	: int;
   public var viewH	: int;
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

 
 class gConfig {
	// content (equivalent DisplayObject) information
	public var x		: int;
	public var y		: int;
	public var width	: int;
	public var height	: int;
	
	//clipping rect
	public var viewX	: int; // = -holder.x
	public var viewY	: int; // = -holder.y
	public var viewW	: int;
	public var viewH	: int;
	
	public var paddingStart : int;
	public var paddingEnd	: int;
	
	//grid info
	public var nRows	: int;
	public var nCols	: int;
	public var isHorz	: Boolean;
	
	//cell info
	public var cellW	: int;
	public var cellH	: int;
	
	//mask margin
	public var mskL	: int;
	public var mskR	: int;
	public var mskT	: int;
	public var mskB	: int;
	
	//public var cacheAsBitmap	: Boolean;//swap items with bitmap when mouse is out of cell view//should cacheAsBitmap run one by one for each frame ?
	public var autoPosition			: Boolean;//automatically set items' positions
	public var centerShortContent	: Boolean;
	
	//clipping mode
	public var useBlendClip		: Boolean;//edge items will be cached as Bitmap & won't interactable
	public var useMaskClip		: Boolean;//hard clip
	public var useAlphaClip		: Boolean;//alpha down edge : you won't be able to change item's alpha, change its children's alpha intead
	
	//item offset
	//public var offsetX	: int;
	//public var offsetY	: int;
	
	//temp
	public var maskMrg		: int;
	
	//callbacks
	public var onPosition	: Function;
	public var onContent	: Function; //should we use dynamic content creation (empty sprites to be holders ?)
	public var onUpdate		: Function;
	
	public function gConfig() {
		x = 0;
		y = 0;
		viewW = 200;
		viewH = 200;
		
		isHorz	= false;
		cellW	= 100;
		cellH	= 20;
		nRows	= 10;
		nCols	= 2;
		
		//maskMrg : 1,
		//paddingEnd : 1,
		//paddingStart: 0,
	}
 }
 
 class gItem {
	public var isValid		: Boolean; //user may hide / alpha down / disable interaction on applying filter
	public var isSelected	: Boolean; //being selected or not
	public var userData		: Object; //any data
	
	//cell information
	public var x		: int;
	public var y		: int;
	//public var w		: int;
	//public var h		: int;
	public var pctView	: Number; //percentage in view
	
	//public var lastUpdateTime	: int; //update time stamp
	//public var lastCacheTime	: int; 
	//public var cache			: BitmapData;
	//public var itemType		: Class; //support multiple items type
}

class gSample {//create samples
	public var _sample		: DisplayObject;
	public var _sampleClass	: Class;
	
	public function setSample(pdo: Object): void {
		if (!_sampleClass || !(pdo is _sampleClass)) {
			try {
				_sampleClass	= getDefinitionByName(getQualifiedClassName(pdo)) as Class;
			} catch (e: Error) { log('setSample', 'Can not find definition <' + getQualifiedClassName(pdo) + '>') }
		}
		
		_sample			= pdo as DisplayObject;
		_config.x		= _sample.x;
		_config.y		= _sample.y;
		_config.cellW	= _sample.width;
		_config.cellH	= _sample.height;
		
		if (_sample.parent) _sample.parent.removeChild(_sample);
		checkMaskSize();
		
		_items = [pdo];
		_nItems = 1;
		//Utils.resizeArray(_items, _sampleClass, _nItems);
		return this;
	}
	
	public function setSampleClass(cls : Class): void {
		if (!cls) {
			log('setSampleClass', 'The sample class can not be null');
			return this;
		}
		
		var sample : DisplayObject;
		try {
			sample = new cls() as DisplayObject;
		} catch (e: Error) {}
		
		if (sample) {
			_sampleClass = cls;
			setSample(sample);
		} else {
			log('setSampleClass', 'The sample class' + cls + ' must be intantiable & it instance should be a DisplayObject');
		}
		
		return this;
	}
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
		
		if (pdo.parent) pdo.parent.addChild(shp);
		
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
		if (!arr) arr = [];
		for (var i:int = arr.length; i < n; i++) { //add more items if needed
			arr.push(new sampleClass());
		}
		return arr;
	}
	
	public static function setView(parentOrViewProps:Object, view:DisplayObject):DisplayObject {
		if (parentOrViewProps is DisplayObjectContainer) {
			parentOrViewProps.addChild(view);
			return parentOrViewProps.getChildByName('sample');
		} else {
			var p:DisplayObjectContainer = parentOrViewProps.parent;
			if (p) p.addChild(view);
			for (var s:String in parentOrViewProps) {
				try {
					view[s] = parentOrViewProps[s];
				} catch (e:Error) {}
			}
			return parentOrViewProps.sample || p.getChildByName('sample');
		}
	}
}

//dynamic class KConfig extends Proxy {
	//protected var _config	: Object;
	//protected var _default	: Object;
	//
	//public function KConfig(defaultConfig: Object) {
		//_default	= defaultConfig;
		//_config		= { };
	//}
	//
	//public function reset(obj: Object): KConfig {
		//_config = obj;
		//return this;
	//}
	//
	//override flash_proxy function getProperty(name:*):* {
		//return _config.hasOwnProperty(name) ? _config[name] : _default[name];
	//}
	//
	//override flash_proxy function setProperty(name:*, value:*):void {
		//_config[name] = value;
	//}
	//
	//override flash_proxy function hasProperty(name:*):Boolean {
		//return _config.hasOwnProperty(name);
	//}
//}

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