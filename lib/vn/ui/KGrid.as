package vn.ui {
	import flash.display.DisplayObject;
	import flash.display.Graphics;
	import flash.display.InteractiveObject;
	import flash.display.Sprite;
	import flash.utils.getTimer;
	
	/**
	 * ...
	 * @author
	 */
	public class KGrid {
		private var _core			: gCore;
		private var _config 		: gConfig;
		private var _cache			: gCache;
		
		
		
		//private var _selectedId		: int; //if there are only 1 item can be selected at a time
		//private var _arrSelected	: Array; //list of selected id
		//
		//private var _hasFilter		: Boolean;
		//private var _arrFiltered	: Array;//list of filtered id
		
		public function KGrid(parentOrViewProps: Object, cacheSize: int = 100) {
			_core		= new gCore();
			_config		= new gConfig();
			_cache		= new gCache(cacheSize);
			_holder		= new Sprite();
			_items		= [];
			
			var sample : DisplayObject = Utils.setView(parentOrViewProps, _holder);
			if (sample) {
				delete sample.parent['sample'];
			}
		}
		
		
		private var _position	: Number;
		public function get position():Number { return _position; }
		public function set position(value:Number):void {
			//_position = value < 0 ? 0 : value>1 ? 1 : value;
			_position = value;
			refresh();
		}
		
		public function get roundedPosition(): Number {
			return _core.cell2Position(_core.position2Cell(_position));
		}
		
		public function getRoundedPosition(p: Number): Number {
			return _core.cell2Position(_core.position2Cell(p));
		}
		
		public function reset(dataLength: int): KGrid {
			_nItems = Math.min(dataLength, _core.nCells);
			Utils.resizeArray(_items, gContainer, _nItems);
			Utils.removeChildren(_holder);
			
			_position		= 0;
			_core.nLength	= dataLength;
			refresh();
			
			//var sprt : Sprite = new Sprite();
			//_holder.parent.addChild(sprt);
			//sprt.x	= _holder.x;
			//sprt.y	= _holder.y;
			//
			//_holder.mask = sprt;
			
			//if (_config.drawDebug) {
				//var g : Graphics = sprt.graphics;
				//g.clear();
				//g.beginFill(0x00ff00, 0.2);
				//g.drawRect(0, 0, _core.viewW, _core.viewH);
				//g.endFill();
			//}
			
			return this;
		}
		
		private var _holder	: Sprite; //TODO : convert to a special sprite where we can override width / height
		private var _nItems : int;
		private var _items	: Array/*gContainer*/;
		
		public function refresh(): void {
			
			var t		: int = getTimer();
			var mc		: gContainer;
			var info	: gInfo;
			
			var first		: int		= _core.position2Cell(_position);
			var clip1		: Number	= _core.getFirstClipPercent(_position);
			var clip2		: Number	= _core.getLastClipPercent(_position);
			var firstClip	: int		= _core.pack2Cell(_core.getFirstClipPack(_position));
			var lastClip	: int		= _core.pack2Cell(_core.getLastClipPack(_position));
			
			//trace(this, _core.scrollL, _core.contentWidth, _core.contentHeight, _core.NPack, firstClip, lastClip);
			
			var pos		: int 	= _core.position2Pixel(_position);
			var off		: int	= int(pos / 1000) * 1000;
			
			_core.isHorz ? (_holder.x = -pos + off) : (_holder.y = -pos + off);
			
			var min : int = Math.min(first + _nItems, _core.nLength);
			min -= first;
			
			for (var i: int = 0; i < min; i++ ) {
				if (first + i < 0) continue; //skip spaces
				
				mc = _items[(first + i) % _nItems];
				
				//trace(i, mc, (first + i) % _nItems)
				
				//swap info
				info		= mc.lastInfo;
				mc.lastInfo = mc.info;
				mc.info		= info;
				
				_holder.addChild(mc); //TODO : SET CHILD INDEX ?
				
				//update info : OPTIMIZE LATER by reducing function calls
				
				//info.cellId		= first + i;
				info.id			= first + i;
				info.x			= _core.getCellX(info.id) - (_core.isHorz ? off : 0);
				info.y			= _core.getCellY(info.id) - (_core.isHorz ? 0 : off);
				info.w			= _core.cellW;
				info.h			= _core.cellH;
				
				info.row		= _core.getCellRow(info.id);
				info.col		= _core.getCellCol(info.id);
				
				
				//trace(info.id, info.x, info.y, info.row, info.col, _core.cellsPerPack, clip1, clip2, firstClip, lastClip);
				
				if (_config.useBlendClip || _config.autoAlpha) {
					if (_core.nLength > _core.nRows * _core.nCols) {
						//trace('a', clip1, clip2);
						if (info.id < firstClip + _core.cellsPerPack) {
							info.pct = clip1;
						} else if (info.id < lastClip) {
							info.pct = 0;
						} else if (info.id < lastClip + _core.cellsPerPack) {
							info.pct = clip2;
						} else {
							info.pct = 1;
						}
					} else {
						info.pct = 0;
					}
					
					//trace(info.id, info.pct)
				}
				
				if (_config.autoPosition) {
					mc.x = info.x;
					mc.y = info.y;
				}
				
				if (_config.autoAlpha) {
					mc.alpha = 1-info.pct;
				}
				
				if (_config.drawDebug) {
					mc.drawDebug();
				}
			}
		}
		
		
	/****************
	 * 	INTERNAL
	 ***************/
		
		public function get cache():gCache { return _cache; } //for global catching
		
	}
}


import flash.display.Bitmap;
import flash.display.DisplayObject;
import flash.display.DisplayObjectContainer;
import flash.display.Graphics;
import flash.display.MovieClip;
import flash.display.Shape;
import flash.display.Sprite;
import flash.events.MouseEvent;
import flash.text.TextField;
import flash.text.TextFieldAutoSize;
import flash.text.TextFormat;
import flash.utils.Dictionary;
import flash.utils.getTimer;

class gInfo {
	public var id			: int; //content id
	public var cellId		: int; //position id
	public var isSelected	: Boolean;
	
	//pre calculated data
	public var x 	: int;
	public var y	: int;
	public var w	: int;
	public var h	: int;
	
	public var row	: int;
	public var col	: int;
	public var pct	: Number; // -1 .. 1
	
	public function gInfo() {
		pct = 1;
		id 	= -1;
	}
}

class gContainer extends Sprite {//contains transient data
	private var tf		:TextField;
	
	public var info		: gInfo;
	public var lastInfo	: gInfo;
	
	public var cache	: Object; //cache always get update to the current id
	public var tween	: Boolean; //only true if grid is being ADD or FILTER IN / OUT
	
	public function gContainer() {
		info		= new gInfo();
		lastInfo 	= new gInfo();
		
		tf = new TextField();
		tf.mouseEnabled = false;
		tf.mouseWheelEnabled = false;
		addChild(tf);
	}
	
	
	public function get isContentChanged(): Boolean {
		return info.id != lastInfo.id;
	}
	
	public function get isPositionChanged(): Boolean {
		return info.cellId != lastInfo.cellId;
	}
	
	public function get isAreaChanged(): Boolean {
		return info.pct != lastInfo.pct;
	}
	
	public function get isSelectionChanged(): Boolean {
		return info.isSelected != lastInfo.isSelected;
	}
	
	
	private static var cnt : int;
	
	public function drawDebug(): void {//draw this item's boundary
		
		//if (info.pct == 1) {
			//trace('completedly clipped - return ');
			//return;
		//}
		
		if ((info.id != lastInfo.id && info.pct != 1) || (lastInfo.pct == 1 && info.pct != 1)) {
			tf.text = "" + info.id;
			
			//TODO : add Debug Draw
			var g : Graphics = graphics;
			g.clear();
			g.beginFill(info.id % 2==0 ? 0x8888ff : 0x5555ff);
			g.drawRect(0, 0, info.w, info.h);
			g.endFill();
			
			//trace('draw ' + ++cnt);
		}
	}
	
	/*
	public function takeSnapShot(): void {
		TODO : add snapshot support
	}*/
	
	public function clear(): void {//remove all previous content
		while (this.numChildren) this.removeChildAt(0);
		
		//if (!snapshot) {
			//this.mouseChildren	= false;
			//this.mouseEnabled	= false;
			//wait for all data loaded then call unlock
		//} else {
			//addChild(snapshot);
		//}
	}
	
	public function unlock(): void {
		//create a snapshot and save in cache
		//snapshot = new Bitmap();
		
		this.mouseChildren	= true;
		this.mouseEnabled	= true;
	}
}

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
	public var autoAlpha			: Boolean;
	public var drawDebug			: Boolean;
	public var centerShortContent	: Boolean;
	
	//clipping mode
	public var useBlendClip		: Boolean;//edge items will be cached as Bitmap & won't interactable
	public var useMaskClip		: Boolean;//hard clip
	//public var useAlphaClip		: Boolean;//alpha down edge : you won't be able to change item's alpha, change its children's alpha intead
	
	//item offset
	//public var offsetX	: int;
	//public var offsetY	: int;
	
	//temp
	public var maskMrg		: int;
	
	//callbacks
	public var onPosition	: Function;
	public var onContent	: Function; //should we use dynamic content creation (empty sprites to be holders ?)
	public var onUpdate		: Function;
	
	public var gOnPosition	: Function;
	public var gOnContent	: Function;
	public var gOnUpdate	: Function;
	
	
	
	public function gConfig() {
		autoAlpha		= true;
		autoPosition	= true;
		drawDebug		= true;
		
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
	
	
	public function gCore() {
		_isHorz	= false;
		_cellW	= 40;
		_cellH 	= 20;
		
		_viewW	= 400;
		_viewH	= 300;
		
		_nRows	= int(_viewH/_cellH) + (_isHorz ? 1 : 0);
		_nCols	= int(_viewW/_cellW) + (_isHorz ? 0 : 1);
		
		refreshContent();
	}
	
	public function get nLength():int { return _nLength; }
	
	public function get nRows():int { return _nRows; }
	public function get nCols():int { return _nCols; }
	public function get isHorz():Boolean { return _isHorz; }
	
	public function get cellW():int { return _cellW; }
	public function get cellH():int { return _cellH; }
	
	public function get viewW():int { return _viewW; }
	public function get viewH():int { return _viewH; }
	
	public function get padStart():int { return _padStart; }
	public function get padEnd():int { return _padEnd; }
	
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
	
	public function get nCells(): int {
		return _nRows * _nCols;
	}
	
	public function getCellCol(idx : int) : int {
		return _isHorz ? int(idx / _nRows) : (idx % _nCols);
	}
	
	public function getCellRow(idx: int) : int {
		return _isHorz ? (idx % _nRows) : int(idx / _nCols);
	}
	
	public function getCellX(idx: int): int {
		var col : int = _isHorz ? int(idx / _nRows) : (idx % _nCols); //inline for better performance
		var pad	: int = (_isHorz && (_nLength > _nRows * _nCols)) ? _padStart : 0; //padding only available if content is NOT short
		
		return col * _cellW + pad;
	}
	
	public function getCellY(idx: int): int {
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
	
	public function get nContentCol(): int {//number of cols if there are no buffer (normal, non-buffer render)
		return (_nContentCol == -1) //check if dirty to recalculate 
					? _nContentCol = _isHorz ? Math.ceil(_nLength / _nRows) : Math.min(_nLength, _nCols)
					: _nContentCol;
	}
	
	public function get nContentRow(): int {//number of rows if there are no buffer (normal, non-buffer render)
		return (_nContentRow == -1)
					? _nContentRow = _isHorz ? Math.min(_nLength, _nRows) : Math.ceil(_nLength / _nCols)
					: _nContentRow;
	}
	
	public function get contentWidth(): int {//content Length by pixel
		if (_contentWidth != -1) return _contentWidth;
		
		//trace("getContent Width :: ", _nContentCol, _nContentRow, _nLength)
		
		var col : int = _nContentCol == -1 ? nContentCol : _nContentCol;
		var pad : int = (_isHorz && (_nLength > _nRows * _nCols)) ? _padStart + _padEnd : 0;
		_contentWidth = col * _cellW + pad;
		
		return _contentWidth;
	}
	
	public function get contentHeight(): int {
		if (_contentHeight != -1) return _contentHeight;
		
		var row	: int = _nContentRow == -1 ? nContentRow : _nContentCol; //save one function call if cached
		var pad	: int = (!_isHorz && (_nLength > _nRows * _nCols)) ? _padStart + _padEnd : 0; //padding : only available if content is NOT short
		_contentHeight = row * _cellH + pad;
		
		//trace(row, _cellH, _contentHeight)
		
		return _contentHeight;
	}
	
	public function get scrollL(): int {//scrolling Length by pixel
		if (_scrollL != -1) return _scrollL;
		
		//trace('get scrollL : ', _contentWidth, _contentHeight);
		
		_scrollL = Math.max(0, _isHorz //short content should not be scrollable
			? ((_contentWidth == -1 ? contentWidth : _contentWidth) - _viewW)
			: ((_contentHeight == -1 ? contentHeight : _contentHeight) - _viewH)
		);
		
		return _scrollL;
	}
	
	//******************************************************************************//
	//								POSITION / RELATION								//
	//******************************************************************************//
	
	public function get relation(): Number {
		if (_contentWidth == 0 || _contentHeight == 0) return 0;
		
		return _isHorz
			? _viewW / ( (_contentWidth != -1) ? _contentWidth : contentWidth)
			: _viewH / ( (_contentHeight != -1) ? _contentHeight : contentHeight);
	}
	
	public function pixel2Position(pixel: int): Number {
		if (_scrollL == 0) return 0;
		return pixel / ((_scrollL == -1) ? scrollL : _scrollL);
	}
	
	public function position2Pixel(position: Number): int {
		if (_scrollL == 0) return 0; //TODO : support short content
		return position * ((_scrollL == -1) ? scrollL : _scrollL);
	}
	
	public function cell2Position(idx: int): Number {//return row / col position
		if (_scrollL == 0) return 0;
		
		var pixel : int = _isHorz ? int(idx / _nRows) * _cellW : int(idx / _nCols) * _cellH + _padStart;
		return pixel / ((_scrollL == -1) ? scrollL : _scrollL);
	}
	
	public function position2Cell(position : Number): int {//return the first cell of the row / col
		if (_scrollL == 0) return 0;
		var pixel 	: int = position * ((_scrollL == -1) ? scrollL : _scrollL) - _padStart;
		return _isHorz ? int(pixel / _cellW) * _nRows : int(pixel / _cellH) * _nCols;
	}
	
	//******************************************************************************//
	//								CLIPPING PERCENTAGE								//
	//******************************************************************************//
	
	public function getFirstClipPercent(position: Number): Number {// 0 : completely visible, -> 1 : completely clipped
		if (_scrollL == 0) return 0; //no clip
		
		var pixel 	: int = position * ((_scrollL == -1) ? scrollL : _scrollL) - _padStart;
		var rounded : int = _isHorz ? int(pixel / _cellW) * _cellW : int(pixel / _cellH) * _cellH;
		return (pixel - rounded) / (_isHorz ? _cellW : _cellH);
	}
	
	public function getLastClipPercent(position: Number): Number {
		if (_scrollL == 0) return 0; //no clip
		
		var viewPx	: int = _isHorz ? _viewW : _viewH;
		var pixel 	: int = position * ((_scrollL == -1) ? scrollL : _scrollL) - _padStart + viewPx;
		var rounded : int = _isHorz ? int(pixel / _cellW) * _cellW : int(pixel / _cellH) * _cellH;
		return 1 - (pixel - rounded) / (_isHorz ? _cellW : _cellH);
	}
	
	//******************************************************************************//
	//								PACKS (= ROW || COL)							//
	//******************************************************************************//
	
	public function get NPack(): int {
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
	
	public function get cellsPerPack(): int {
		return _isHorz ? _nRows : _nCols;
	}
		
	public function getFirstClipPack(position: Number): int {
		if (_scrollL == 0) return 0; //no clip
		
		var pixel 	: int = position * ((_scrollL == -1) ? scrollL : _scrollL) - _padStart;
		return int(pixel / (_isHorz ? _cellW : _cellH));
	}
	
	public function getLastClipPack(position: Number): int {
		if (_scrollL == 0) return 0; //no clip
		
		var viewPx	: int = _isHorz ? _viewW : _viewH;
		var pixel 	: int = position * ((_scrollL == -1) ? scrollL : _scrollL) - _padStart + viewPx;
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
