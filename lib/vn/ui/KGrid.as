package vn.ui {
	import flash.display.DisplayObject;
	
	
	/**
	 * ...
	 * @author
	 */
	public class KGrid {
		private var _core		: gCore;
		private var _config 	: gConfig;
		private var _cache		: gCache;
		
		private var _containers	: Array/*gContainer*/;
		
		public function KGrid(parentOrViewProps: Object, cacheSize: int) {
			_core = new gCore();
			
		}
		
		public function setSample(): KGrid {
			
			return this;
		}
		
		public function setViewSize(w: int, h: int): KGrid {
			
			return this;
		}
		
		private var _firstPack	: int; //first pack being shown
		private var _stamp		: int; //reset time stamp : force update content if an item's time stamp < _stamp
		
		public function reset(dataLength: int): KGrid {
			_core._nLength = dataLength;
			
			
			
		}
		
		
		
		
	}
}

import flash.display.Bitmap;
import flash.display.Sprite;

class gContainer extends Sprite {//contains transient data
	public var index		: int;
	public var isActive		: Boolean;
	public var isSelected	: Boolean;
	
	public var stamp		: int; //time stamp for last content update
	
	public var lastArea		: int; //use to detect area changes and update alpha / clipping ...
	public var area			: int; //might be IN_VIEW > PARTLY_IN_VIEW > BUFFER > PARTLY_BUFFER > HIDDEN
	
	public var guIndex		: int; //the order in this Update call - different for each item (0 .. guTotal-1)
	public var guTotal		: int; //total items that need to be update in this call
	
	public var cache		: Object; //normally contains a snapshot of this
	public var snapshot		: Bitmap;
	
	public function drawDebug() {//draw this item's boundary
		
	}
	
	public function takeSnapShot(): void {
		
	}
	
	public function clear(): void {//remove all previous content
		while (this.numChildren) this.removeChildAt(0);
		
		if (!snapshot) {
			this.mouseChildren	= false;
			this.mouseEnabled	= false;
			//wait for all data loaded then call unlock
		} else {
			addChild(snapshot);
		}
	}
	
	public function unlock(): void {
		//create a snapshot and save in cache
		//snapshot = new Bitmap();
		
		this.mouseChildren	= true;
		this.mouseEnabled	= true;
	}
}

import flash.display.DisplayObject;
import flash.display.DisplayObjectContainer;
import flash.display.Graphics;
import flash.display.MovieClip;
import flash.display.Shape;
import flash.events.MouseEvent;
import flash.text.TextField;
import flash.text.TextFieldAutoSize;
import flash.text.TextFormat;
import flash.utils.Dictionary;
import flash.utils.getTimer;

class gCache {
	protected var _cache	: Dictionary;
	protected var _fixed	: Array;//hard reference to prevent gc
	protected var _fsize	: int;//length of fixed
	protected var _index	: int;//start index in fixed size
	
	/* for tracking effectiveness */
	protected var _plus		: int;
	protected var _total	: int;
	
	public function gCache(fixedSize: int = 0) {
		_fsize = fixedSize;
		_fixed = [];
		_cache = new Dictionary(true);
	}
	
	public function clearAll():void {//clear cache
		_fixed = [];
		_cache = new Dictionary(true);
	}
	
	public function keep(item: Object): void {//keep an item in fixed Array
		_fixed[_index]	= item;
		_index = (++_index) % _fsize;
	}
	
	public function register(item: *, id: String, useKeep: Boolean = true): void {
		_cache[item]		= id;
		if (useKeep) keep(item);
	}
	
	public function get(id: String): * {
		var ro : *;
		
		for (var o: * in _cache) {
			if (_cache[o] == id) {
				_plus ++;
				ro = o;
				break;
			}
		}
		_total++;
		//trace(ro, effective);
		return ro;
	}
	
	public function get effective(): Number {
		return _total == 0 ? 0 : _plus / _total;
	}
}

class gConfig {
	
	// content (equivalent DisplayObject) information
	public var x		: int;
	public var y		: int;
	public var width	: int;
	public var height	: int;
	
	
	
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

/***********************
 * 		GRID INFO
 **********************/

class gCore {//grid core
	
	private var _nLength	: int; //data length
	
	//grid configuration
	private var _nRows		: int; 
	private var _nCols		: int;
	private var _isHorz		: Boolean;
	
	//cell configuration
	private var _cellW		: int;
	private var _cellH		: int;
	
	//view info
	private var _viewW		: int;
	private var _viewH		: int;
	
	//padding
	private var _padStart	: int;
	private var _padEnd		: int;

	//******************************************************************************//
	//									SETTERS										//
	//******************************************************************************//
	
	public function set nLength(value:int):void  {
		_nLength = value;
		refreshContent();
	}
	
	public function set nRows(value:int):void {
		_nRows = value; //set viewH
		refreshContent();
	}
	
	public function set nCols(value:int):void {
		_nCols = value; //set viewW
		refreshContent();
	}
	
	public function set isHorz(value:Boolean):void {
		_isHorz = value; 
		refreshContent();
	}
	
	public function set cellW(value:int):void {
		_cellW = value; //set viewW
		refreshContent();
	}
	
	public function set cellH(value:int):void {
		_cellH = value; //set viewH
		refreshContent();
	}
	
	private function refreshContent(): void {
		_nContentCol 	 = -1;
		_nContentRow 	 = -1;
		_contentWidth	 = -1;
		_contentHeight	 = -1;
		_scrollL		 = -1;
	}
	
	//******************************************************************************//
	//									CELL										//
	//******************************************************************************//
	
	private function getCellCol(idx : int) : int {
		return _isHorz ? int(idx / _nRows) : (idx % _nCols);
	}
	
	private function getCellRow(idx: int) : int {
		return _isHorz ? (idx % _nRows) : int(idx / _nCols);
	}
	
	private function getCellX(idx: int): int {
		var col : int = _isHorz ? int(idx / _nRows) : (idx % _nCols); //inline for better performance
		var pad	: int = (_isHorz && (_nLength > _nRows * _nCols)) ? _padStart : 0; //padding only available if content is NOT short
		
		return col * _cellW + pad;
	}
	
	private function getCellY(idx: int): int {
		var row : int = _isHorz ? (idx % _nRows) : int(idx / _nCols); //inline for better performance
		var pad	: int = (!_isHorz && (_nLength > _nRows * _nCols)) ? _padStart : 0; //padding only available if content is NOT short
		
		return row * _cellH + pad;
	}
	
	//******************************************************************************//
	//									CONTENT										//
	//******************************************************************************//
	
	private var _nContentCol 	: int; //cache : set to -1 if dirty
	private var _nContentRow 	: int; 
	private var _contentWidth	: int;
	private var _contentHeight	: int;
	private var _scrollL		: int;
	
	private function get nContentCol(): int {//number of cols if there are no buffer (normal, non-buffer render)
		return (_nContentCol == -1) //check if dirty to recalculate 
					? _nContentCol = _isHorz ? Math.ceil(_nLength / _nRows) : Math.min(_nLength, _nCols)
					: _nContentCol;
	}
	
	private function get nContentRow(): int {//number of rows if there are no buffer (normal, non-buffer render)
		return (_nContentRow == -1)
					? _nContentRow = _isHorz ? Math.min(_nLength, _nRows) : Math.ceil(_nLength / _nCols)
					: _nContentRow;
	}
	
	private function get contentWidth(): int {//content Length by pixel
		if (_contentWidth != -1) return _contentWidth;
		
		var col : int = (_nContentCol == -1) ? nContentCol : _nContentCol;
		var pad : int = (_isHorz && (_nLength > _nRows * _nCols)) ? _padStart + _padEnd : 0;
		_contentWidth = col * _cellW + pad;
		
		return _contentWidth;
	}
	
	private function get contentHeight(): int {
		if (_contentHeight != -1) return _contentHeight;
		
		var row	: int = _nContentRow == -1 ? nContentRow : _nContentCol; //save one function call if cached
		var pad	: int = (!_isHorz && (_nLength > _nRows * _nCols)) ? _padStart + _padEnd : 0; //padding : only available if content is NOT short
		_contentHeight = row * _cellH + pad;
		
		return _contentHeight;
	}
	
	private function get scrollL(): int {//scrolling Length by pixel
		if (_scrollL != -1) return _scrollL;
		
		_scrollL = Math.max(0, _isHorz //short content should not be scrollable
			? ((_contentWidth == -1 ? _contentWidth : contentWidth) - _viewW)
			: ((_contentHeight == -1 ? _contentHeight : contentHeight) - _viewH)
		);
		
		return _scrollL;
	}
	
	//******************************************************************************//
	//								POSITION / RELATION								//
	//******************************************************************************//
	
	private function get relation(): Number {
		if (_contentWidth == 0 || _contentHeight == 0) return 0;
		
		return _isHorz
			? _viewW / ( (_contentWidth != -1) ? _contentWidth : contentWidth)
			: _viewH / ( (_contentHeight != -1) ? _contentHeight : contentHeight);
	}
	
	private function pixel2Position(pixel: int): Number {
		if (_scrollL == 0) return 0;
		return pixel / (_scrollL == -1) ? scrollL : _scrollL;
	}
	
	private function position2Pixel(position: Number): int {
		if (_scrollL == 0) return 0; //TODO : support short content
		return position * (_scrollL == -1) ? scrollL : _scrollL;
	}
	
	private function cell2Position(idx: int): Number {//return row / col position
		if (_scrollL == 0) return 0;
		
		var pixel : int = _isHorz ? int(idx / _nCols) * _cellW : int(idx / _nRows) * _cellH + _padStart;
		return pixel / (_scrollL == -1) ? scrollL : _scrollL;
	}
	
	private function position2Cell(position : Number): int {//return the first cell of the row / col
		if (_scrollL == 0) return 0;
		
		var pixel 	: int = position * ((_scrollL == -1) ? scrollL : _scrollL) - _padStart;
		return _isHorz ? Math.round(pixel / _cellW) * _nRows : Math.round(pixel / _cellH) * _nCols;
	}
	
	//******************************************************************************//
	//								CLIPPING PERCENTAGE								//
	//******************************************************************************//
	
	public function getFirstClipPercent(position: Number): Number {// 0 : completely visible, -> 1 : completely clipped
		if (_scrollL == 0) return 0; //no clip
		
		var pixel 	: int = position * ((_scrollL == -1) ? scrollL : _scrollL) - _padStart;
		var rounded : int = _isHorz ? int(pixel / _cellW) * _cellW : int(pixel / _cellH) * _cellH);
		return (pixel - rounded) / (_isHorz ? _cellW : _cellH);
	}
	
	public function getLastClipPercent(position: Number): Number {
		if (_scrollL == 0) return 0; //no clip
		
		var pixel 	: int = position * ((_scrollL == -1) ? scrollL : _scrollL) - _padStart + _viewH;
		var rounded : int = _isHorz ? int(pixel / _cellW) * _cellW : int(pixel / _cellH) * _cellH);
		return 1 - (pixel - rounded) / (_isHorz ? _cellW : _cellH);
	}
	
	//******************************************************************************//
	//								PACKS (= ROW || COL)							//
	//******************************************************************************//
	
	public function getNPack(): int {
		return Math.ceil(_nLength / (_isHorz ? _nRows : _nCols));
	}
	
	public function pixel2Pack(pixel: int): int {
		return int((pixel - _padStart) / (_isHorz ? _cellW : _cellH));
	}
	
	public function pack2Pixel(pack: int): int {
		return pack * (_isHorz ? _cellW : _cellH) + _padStart;
	}
	
	public function pack2Cell(pack: int): int {
		return pack * (_isHorz ? _nRows : _nCols);
	}
	
	public function cell2Pack(cell: int): int {
		return int(cell / (_isHorz ? _nRows : _nCols));
	}
	
	public function get cellPerPack(): int {
		return _isHorz ? _nRows : _nCols;
	}
	
	public function getFirstClipPack(position: Number): int {
		if (_scrollL == 0) return 0; //no clip
		
		var pixel 	: int = position * ((_scrollL == -1) ? scrollL : _scrollL) - _padStart;
		return int(pixel / (_isHorz ? _cellW : _cellH));
	}
	
	public function getLastClipPack(position: Number): int {
		if (_scrollL == 0) return 0; //no clip
		
		var pixel 	: int = position * ((_scrollL == -1) ? scrollL : _scrollL) - _padStart + _viewH;
		return int(pixel / (_isHorz ? _cellW : _cellH));
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