package vn.ui {
	import flash.display.DisplayObject;
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.events.MouseEvent;
	import flash.utils.Dictionary;
	/*
	-----------------------------------------------------------------
	KMenu by thienhaflash (thienhaflash@gmail.com)
		
	Updated			: 10.April.2012
	Callbacks 		: 
		itemClass 	: .update(menuItem)
		panelClass	: .update(arrChildren, w, h)
		
	Features 		: 
		Supports unlimited menu levels
		Supports show an abitrary number menu levels
		Support manage menu items by Id, with an automatic index based autoId (best for debug)
		Disable / Enable click on MenuItems that has sub Menu
		Automatic mouse handling
			RollOver to show subMenu
			RollOut to hide
			Click to set active KMenu
			
		Configurable for by each MENU ITEM or by each LEVEL
			.width			: set minimum item width, still autosize if the content exceed size
			.margin			: spacing that pad around the textfield of itemView
			.clickable		: enable / disable click on this item
			.itemClass		: view class to instantiate (itemView), elements used for automatic update : .txtLabel, .mcBg
							  or use a custom update function :  .update(menuItem)
				
			.panelX			: set absolute position of this panel
			.panelY			: -
			.panelColor		: set color for this panel
			.panelMargin	: margin for menuItem containers
			.panelAlign		: position of the panel aligining to its parent MenuItem
							  supported values : TL, TC, TR, BL, BC, BR, LT, LC, LB, RT, RC, RB
			.panelIsHorz 	: control whether children of this menuItem will be laid out vertically or horizontally
			.panelClass		: view class to instantiate (panelView), elements used for automatic update : .mcHolder, .mcBg
							  or use a custom update function :  .update(menuItem)
	------------------------------------------------------------------
	*/
	
	public class KMenu {
		private var _dictId : Dictionary;
		private var _view	: MovieClip;
		private var _root	: MenuItem;
		
		public var _onClickItem : Function;
		
		public function KMenu(onClickItem : Function = null) {
			_onClickItem	= onClickItem;
			_levelConfigs	= [];
		}
		
		public function reset(parentOrViewProps : Object, ...items): KMenu {
			createSubMenu(items);
			
			if (parentOrViewProps is DisplayObjectContainer) {
				parentOrViewProps.addChild(view);
			} else {
				var p : DisplayObjectContainer = parentOrViewProps.parent;
				if (p) p.addChild(view);
				for (var s : String in parentOrViewProps) {
					try {
						view[s] = parentOrViewProps[s];
					} catch (e: Error) {}
				}
			}
			
			return this;
		}
		
		private var _activeId : String;
		
		public function unActive(): void {
			if (_activeId) {
				var mni : MenuItem = _dictId[_activeId];
				if (mni.itemView) mni.itemView.setActive(false); //might not yet being created
				mni.isActive = false;
				
				//recursive
				var p : MenuItem = mni.parent;
				while (p.level) {
					if (p.itemView) p.itemView.setActive(false);
					p.isActive = false;
					p = p.parent;
				}
				_activeId = null;
			}
		}
		
		public function active(autoId: String): void {
			if (_activeId) unActive();
			var mni : MenuItem = _dictId[autoId];
			if (mni) {
				if (mni.itemView) mni.itemView.setActive(true); //might not yet being created
				mni.isActive = true;
				
				//recursive
				var p : MenuItem = mni.parent;
				while (p.level) {
					if (p.itemView) p.itemView.setActive(true);
					p.isActive = true;
					p = p.parent;
				}
				_activeId = autoId;
			}
		}
		
		public function setId(id: *, menuItem: MenuItem): void {
			_dictId[id] = menuItem;
		}
		
		private function createSubMenu(children: Array, parentId: String = null): void {
			if (!parentId) {
				_dictId		= new Dictionary();
				_root		= new MenuItem(this, null, 0, 'root');
			}
			
			var pMenu	: MenuItem	= parentId ? _dictId[parentId] : _root;
			var level	: int		= parentId ? pMenu.level : 0;
			var autoId	: String	= parentId ? pMenu.autoId 	: '';
			var l		: int 		= children.length;
			
			var child	: * ;
			var iMenu	: MenuItem;
			var arr		: Array;
			
			for (var i: int = 0; i < l; i++) {
				child	= children[i];
				
				if (!child) {
					trace('null menuItem at : ', autoId + '.' + i);
					continue;
				} else if (child is Array) {
					var child0 : * = child[0];
					iMenu = new MenuItem(this, pMenu, i, child0);
					if (!(child0 is String)) iMenu.resetObject(child0);
					
					if (child.length == 2) {
						arr = child[1];
					} else {
						child.shift();
						arr = child;
					}
				} else if (child is String) {
					iMenu	= new MenuItem(this, pMenu, i, child);
					arr		= null;
				} else {
					iMenu	= new MenuItem(this, pMenu, i).resetObject(child);
					arr		= child.children; //dynamic property
				}
				
				_dictId[iMenu.autoId] = iMenu;
				if (arr) createSubMenu(arr, iMenu.autoId);
			}
			
			if (!parentId) {
				_root.updateChildrenView();
				_view = _root.childrenView;
				_view.addEventListener(MouseEvent.ROLL_OUT, _onMouseOut);
			}
		}
		
		private function _onMouseOut(e:MouseEvent):void {
			//trace(this, 'out !');
			_root.hideSameLevel(_root.children, false);
			
			//show active items
			if (_activeId) {
				trace('backToActiveId : ', activeId);
				_root.hideSameLevel(_root.children, true);
				
				var ids : Array = _activeId.split('.');
				ids = ids.length < (_keepShowLevel + 1) ? ids : ids.slice(0, _keepShowLevel + 1);
				var mni : MenuItem = _dictId[ids.join('.')];
				if (mni) mni.parent.showChildren();
			}
		}
		
		public function get view():MovieClip { return _view; }
		
		public function get activeId():* { 
			if (!_activeId) return null;
			var item : MenuItem = _dictId[_activeId];
			return item.id || _activeId;
		}
		
		/********  ENABLE / DISABLE CLICK ON PARENT ***********/
		private var _allowParentClick : Boolean;
		public function get allowParentClick():Boolean { return _allowParentClick; }		
		public function set allowParentClick(value:Boolean):void { _allowParentClick = value; }
		
		/********  SET NUMBER OF LEVELS GET VISIBLE  **********/
		private var _keepShowLevel	: int = 1;
		public function get keepShowLevel():int { return _keepShowLevel; }
		public function set keepShowLevel(value:int):void { _keepShowLevel = value; _onMouseOut(null); }
		
		/********  SET LEVEL CONFIG  **********/
		private var _levelConfigs	: Array;
		public function getLevelConfig(level: int): Object { return _levelConfigs[level]; }
		public function setLevelConfig(level: int, config: Object):KMenu {
			_levelConfigs[level] = config;
			return this;
		}
		public function setLevelConfigs(...rest): KMenu {
			_levelConfigs = rest;
			if (_root) _root.updateChildrenView(true);
			return this;
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
import flash.events.TextEvent;
import flash.events.TimerEvent;
import flash.geom.ColorTransform;
import flash.text.TextField;
import flash.text.TextFieldAutoSize;
import flash.text.TextFormat;
import flash.utils.Timer;

class MenuItem {
	public var menu			: Object;
	public var autoId		: String; //internal autoId
	public var level		: int;
	public var index		: int;
	public var parent		: MenuItem;
	public var children		: Array; //Vector<MenuItem>
	
	public var label		: String;
	public var id			: *;
	/** Special properties :
			.width			: set minimum item width, still autosize if the content exceed size
			.margin			: spacing that pad around the textfield of itemView
			.itemClass		: view class to instantiate (itemView)
			.clickable		: whether should we allow clicking on menuItems that contains children
			
			.panelClass		: view class to instantiate (panelView)
			.panelX			: set absolute position of this panel
			.panelY			: -
			.panelColor		: color for this panel
			.panelMargin	: margin for menuItem containers
			.panelAlign		: where should we put the children items TCB | LCR
			.panelIsHorz 	: control whether children of this menuItem will be laid out vertically or horizontally
	 */
	public var config		: Object; //other configurations
	
	public function MenuItem(menu: Object, parent: MenuItem, index: int, label: String = 'MenuItem') {
		this.menu = menu;
		
		if (parent) {
			parent.children ||= [];
			parent.children[index] = this;
			this.parent = parent;
		}
		
		this.label	= label;
		this.level	= parent ? parent.level + 1 : 0;
		//we can not use '' to then append the indexes as it might be overwritten by user set id
		//autoId need to be unique, so we prepend an '@uto1d'
		this.autoId	= level == 0	? '@uto1d.' : 
					  level == 1	? '@uto1d.' + index : 
							(parent.autoId +'.' + index);
		
		this.index	= index;
	}
	
	public function resetObject(config: Object): MenuItem {
		this.label	= config.label;
		this.config = config;
		
		//we must check if config own an Id property as this id might be 0
		//or something that then being converted to a false
		if (config.hasOwnProperty('id')) {
			id		= config.id;
			menu.setId(id, this);
		}
		
		return this;
	}
	
/*********************
 * 	ITEM VIEW
 ********************/
	
	public var itemView		: MovieClip; //attach to this view !
	
	public function updateItemView(): void {
		if (itemView) return;
		
		var itemClass : Class = getConfig('itemClass', MenuItemMC);
		itemView = new itemClass() as MovieClip;
		
		if (itemView.hasOwnProperty('update')) {
			itemView.update(this);
		} else {
			_defaultUpdateItem();
		}
		
		itemView.width = Math.max(itemView.width, getConfig('width', 0));
		itemView.addEventListener(MouseEvent.CLICK, onClickItem);
		itemView.addEventListener(MouseEvent.ROLL_OVER, onOverItem);
		//trace(this, 'updateItemView', autoId);
		if (isActive) itemView.setActive(true);
	}
	
	private function _defaultUpdateItem(): void {
		var tf		: TextField		= itemView.getChildByName('txtLabel') as TextField;
		var bg 		: DisplayObject	= itemView.getChildByName('mcBg');
		var margin	: int			= getConfig('margin', 5)
		
		if (tf) {
			tf.text		= label;
			tf.x		= margin;
			tf.y		= margin;
		}
		
		if (bg) {
			bg.width 	= margin * 2 + tf.width;
			bg.height 	= margin * 2 + tf.height;
			bg.alpha	= 0;
		}
	}
	
	private function onOverItem(e:MouseEvent):void { showChildren(); }
	
	private function onClickItem(e:MouseEvent):void {
		if (config && config.hasOwnProperty('clickable')) {
			if (!config.clickable) return;
		} else if (!menu.allowParentClick && children) {
			return;
		}
		
		menu._onClickItem ? menu._onClickItem(id ? id : autoId) : trace('onClickItem :: <', autoId, '>', id);
		active();
	}
	
/*********************
 * 	CHILDREN VIEW
 ********************/
	
	public var childrenView	: MovieClip;
	
	public function getChildrenItemViews(): Array {
		var arr : Array = [];
		var l	: int = children.length;
		for (var i: int = 0; i < l; i++) {
			var mi : MenuItem = children[i];
			arr.push(mi.itemView);
		}
		
		return arr;
	}
	
	public function getConfig(prop: String, defaultValue: * ): * {
		var lvConfig : Object = menu.getLevelConfig(level);
		return	(config && config.hasOwnProperty(prop)) ? config[prop] :
				(lvConfig && lvConfig.hasOwnProperty(prop)) ? lvConfig[prop] : defaultValue;
	}
	
	public function updateChildrenView(force: Boolean = false): void {
		if ((!children || childrenView) && !force) return;
		
		var panelClass : Class = getConfig('panelClass', MenuMC);
		childrenView ||= (new panelClass() as MovieClip);
		
		var isHorz 	: Boolean	=	getConfig('panelIsHorz', level == 0);
		var margin	: int		=	getConfig('panelMargin', 0);
		var l		: int = children.length;
		var w		: int = 0;
		var h		: int = 0;
		
		//trace(this, 'updateChildrenView', level, l);
		
		for (var i: int = 0; i < l; i++) {
			var mi : MenuItem = children[i];
			mi.updateItemView();
			
			if (isHorz) {
				mi.itemView.x = w + margin;
				mi.itemView.y = margin;
				
				w += mi.itemView.width;
				h = Math.max(mi.itemView.height, h);
			} else {
				mi.itemView.x = margin;
				mi.itemView.y = h+margin;
				
				w = Math.max(mi.itemView.width, w);
				h += mi.itemView.height;
			}
		}
		
		if (!isHorz) {//reset size for items
			for (i = 0; i < l; i++) {
				children[i].itemView.width = w;
			}
		}
		
		if (childrenView.hasOwnProperty('update')) {
			childrenView.update(getChildrenItemViews(), w + 2 * margin, h + 2 * margin);
		} else {
			_defaultUpdateChildrenView(getChildrenItemViews(), w + 2 * margin, h + 2 * margin);
		}
	}
	
	private function _defaultUpdateChildrenView(arr: Array, w:int, h: int): void {
		//panelColor
		var holder	: Sprite		= childrenView.getChildByName('mcHolder') as Sprite;
		var bg		: DisplayObject	= childrenView.getChildByName('mcBg');
		var color	: int			= getConfig('panelColor', -1);
		
		if (holder) {
			Utils.removeChildren(holder);
			for (var i: int = 0; i < arr.length; i++) {
				holder.addChild(arr[i]);
			}
		}
		
		if (bg) {
			bg.width = w;
			bg.height = h;
			if (color != -1) Utils.tint(bg, color);
		}
	}
	
/************************
 * 	SHOW/HIDE CHILDREN
 ************************/	
	
	private var _isShowingChildren	: Boolean;
	
	public function showChildren(): void {
		if (!parent) return;
		
		//forcely hide all same levels
		hideSameLevel(parent.children, true);
		if (!isActive) {
			itemView.setOver(true);
			p = parent;
			while (p.level) {
				if (!p.isActive) p.itemView.setOver(true);
				p = p.parent;
			}
		}
		
		
		var p : MenuItem = parent;
		while (p.level) {//show all parents
			if (!p.isShowingChildren) p.showChildren();
			p = p.parent;
		}
		
		if (children) {
			updateChildrenView();
			//trace('showChildren', autoId);
			
			//call to cancel parent hide timers
			itemView.parent.addChild(childrenView);
			var align	: String	= getConfig('panelAlign', null);
			var tx 		: int;
			var ty 		: int;
			
			if (align) {
				var first	: String = align.charAt(0);
				var second	: String = align.charAt(1);
				
				if (first == 'T' || first == 'B') {
					ty = itemView.y +	((first == 'T') ? -childrenView.height : itemView.height);
					tx = itemView.x +	((second == 'L') ? 0 : 
										(second == 'R') ? itemView.width - childrenView.width : 
										(itemView.width - childrenView.width) / 2);
				} else if (first == 'L' || first == 'R') {
					tx	= itemView.x + (first == 'L' ? - childrenView.width : itemView.width);
					ty 	= itemView.y + (second == 'T' ? 0 :
										second == 'B' ? itemView.height - childrenView.height : 
										(itemView.height - childrenView.height) / 2);
				}
			} else {
				tx	= itemView.x + (level == 1 ? 0 : itemView.width);
				ty	= itemView.y + (level == 1 ? itemView.height : 0);
			}
			
			childrenView.x = getConfig('panelX', tx);
			childrenView.y = getConfig('panelY', ty);
			_isShowingChildren	= true;
		}
	}
	
	public function hideSameLevel(arr: Array, force: Boolean): void {
		//trace(this, 'hideSameLevel :: ', level);
		//var arr : Array = parent.children;
		var mni : MenuItem;
		for (var i: int = 0; i < arr.length; i++) {
			mni = arr[i];
			mni.hideChildren(force);
		}
	}
	
	public function hideChildren(force: Boolean = false): void {
		if (level > 0 && !isActive) itemView.setOver(false);
		
		if (_isShowingChildren) {//recursive
			hideSameLevel(children, force);
			if (force || (level > menu.keepShowLevel)) {
				//trace('hideChildren::', label, level, menu.keepShowLevel);
				childrenView.parent.removeChild(childrenView);
				_isShowingChildren	= false;
			}
		}
	}
	
	public function get isShowingChildren():Boolean { return _isShowingChildren; }
	
/************************
 * 		ACTIVE
 ************************/
	
	public var isActive : Boolean;
	public function active(): void { menu.active(autoId); }
	public function unActive(): void { menu.unActive(); }
}

class MenuMC extends MovieClip {
	public var bg		: Shape;
	public var holder	: Sprite; //contains children
	
	public function MenuMC() {
		bg		= Utils.newRect(0xD6D6D6, 'mcBg', this);
		holder	= new Sprite();
		holder.name = 'mcHolder';
		
		//addChild(bg);
		addChild(holder);
	}
}

class MenuItemMC extends MovieClip {//default skin
	public var menuItem	: MenuItem;
	public var tf		: TextField;
	public var bg		: Shape;
	
	public function MenuItemMC() {
		bg = Utils.newRect(0x0000ff, 'mcBg', this);
		tf = Utils.newTextField('txtLabel', this);
		bg.height = tf.height;
		
		mouseChildren = false;
		buttonMode = true;
	}
	
	public function setOver(value: Boolean): void { bg.alpha = value ? 0.1 : 0; }
	public function setActive(value: Boolean): void { bg.alpha = value ? 0.3 : 0; }
	override public function set width(value:Number):void { bg.width = value; }
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
	
	public static function tint(pdo : DisplayObject, color: int): void {
		var ct : ColorTransform = new ColorTransform();
		ct.color = color;
		pdo.transform.colorTransform = ct;
	}
}