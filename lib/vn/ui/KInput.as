package vn.ui {
	import flash.display.BlendMode;
	import flash.display.DisplayObject;
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.FocusEvent;
	import flash.events.KeyboardEvent;
	import flash.text.TextField;
	import flash.ui.Keyboard;
	import flash.utils.setTimeout;
	
	/**
	 * KInput component that transform a simple textfield to an input area with hint, regular expression checks
	 * differrent theme for input states (valid, invalid, hint, input), handling focus and keyboard shortcut
	 * 
	 * @author	thienhaflash (thienhaflash@gmail.com)
	 * @version 0.1.0
	 * @updated	20 October 2011
	 * @features	Support once listeners and each frame callbacks with parameters
	 * 				Support timeline configuration (should be 1 MovieClip contains a textfield, named txt)
	 * 				Support default config + default skin
	 * 				Stand alone - no other depedencies needed
	 * 				Support live editing callbacks - allow mod plugins (autoComplete / hintBox / ...)
	 * 
	 */
	
	/**********************  EXAMPLE USASGES *****************************
			
		1.	From code	:
			[code]
				new KInput(this).setHint('hello, input something here !');
			[/code]
			
			
		2.	From timeline textfield / timeline MovieClip
			[code]
				new KInput(this).setHint('hello, input something here !')
								.setSkin(mc);
			[/code]
			
			
		3.	To change theme	:
			[code]
				//we need firstly create a new theme
				KInput.addTheme(	'dark',	{color: 0xFFFFFF} //input
									,	{color: 0x555555, italic: true} //hint
									,	{border: true, borderColor: 0xff0000, color: 0xFF0000} //invalid
									,	{color : 0xAAAAAA}
								); 
				
				//then use it
				input.themeId = 'dark';
			[/code]
			
	**********************************************************************/
	public class KInput {
		public static function addTheme(id: String, inputFormat: Object, hintFormat: Object, inValidFormat: Object, validFormat: Object, useAsDefault: Boolean = false): void {
			InputTheme.newTheme(id, inputFormat, hintFormat, inValidFormat, validFormat, useAsDefault);
		}
		
		public function KInput(parentOrViewProps: * = null) {
			_config		= new InputConfig();
			_content	= '';
			trace(skin);
			if (parentOrViewProps) InputUtils.setView(parentOrViewProps, skin);
		}
		
	/***************************
	 * 	SHORT CUT / CALLBACK
	 * 
	 ***************************/
		
		private var _onChange_Func 		: Function;
		private var _onChange_Params 	: Array;
		
		private var _onComplete_Func	: Function;
		private var _onComplete_Params	: Array;
		
		public function onInputChange(func: Function, params : Array = null): KInput {
			_onChange_Func		= func;
			_onChange_Params	= params;
			return this;
		}
		
		public function onInputComplete(func: Function, params : Array = null): KInput {
			_onComplete_Func	= func;
			_onComplete_Params	= params;
			return this;
		}
		
	/********************
	 * 		TARGET
	 ********************/
		
		private var _skin			: DisplayObject;
		private var _textfield		: TextField;
		
		public function get skin():DisplayObject { 
			if (!_skin) setSkin(InputUtils.getDefaultTextField());
			return _skin;	
		}
		
		public function set skin(pdo:DisplayObject):void { setSkin(pdo); }
		
		public function setSkin(pdo:DisplayObject):KInput {
			if (_textfield) removeTextField(_textfield);
			if (!pdo) return this;
			
			_textfield	= pdo as TextField;
			if (!_theme) _theme = InputTheme.getTheme(null); //get default theme
			
			if (_textfield) { //use default settings
				addTextField(_textfield);
			} else if (pdo is MovieClip) {
				var mc : MovieClip = pdo as MovieClip;
				_textfield = (mc.txt || mc.getChildAt(0)) as TextField;
				addTextField(_textfield);
				setConfig(mc.inputConfig);
			} else {
				trace(this, 'Error trying to setSkin to an invalid target, named ', pdo.name);
				return this;
			}
			_skin = pdo;
			return this;
		}
		
		private function addTextField(tf: TextField): void {
			tf.blendMode	= BlendMode.LAYER;
			oProps			= _theme.saveOriginalProps(_textfield);
			
			tf.text			= (_content == '') ? _config.hint : _content;
			refreshTheme();
			
			tf.addEventListener(FocusEvent.FOCUS_IN,		_onGainFocus);
			tf.addEventListener(FocusEvent.FOCUS_OUT,		_onLooseFocus);
			tf.addEventListener(KeyboardEvent.KEY_DOWN,		_onKeyDown);
			tf.addEventListener(Event.CHANGE,				_onTextChanged);
		}
		
		private function removeTextField(tf: TextField): void {
			_theme.revert2OriginalProps(tf, oProps);//return properties
			
			tf.removeEventListener(FocusEvent.FOCUS_IN,		_onGainFocus);
			tf.removeEventListener(FocusEvent.FOCUS_OUT,	_onLooseFocus);
			tf.removeEventListener(KeyboardEvent.KEY_DOWN,	_onKeyDown);
			tf.removeEventListener(Event.CHANGE,			_onTextChanged);
		}
		
		private function _onKeyDown(e: KeyboardEvent): void {
			if (e.keyCode == Keyboard.ENTER && !_textfield.multiline) {//apply new content
				killFocus();
				
			} else if (e.keyCode == Keyboard.ESCAPE) {//revert to old content
				_textfield.text	= _content;
				killFocus();
			}
		}
		
		private function _onTextChanged(e: Event): void {
			//TODO : adding support for delay
			if (_onChange_Func != null) _onChange_Func.apply(null, _onChange_Params);
		}
		
	/********************
	 * 		FOCUS
	 ********************/
		
		private var _isFocus 	: Boolean;
		
		public function get isFocus():Boolean { return _isFocus; }
		public function set isFocus(value:Boolean):void { value ? gainFocus() : killFocus(); }
		
		private function gainFocus(): void { _textfield.stage.focus = _textfield; }
		private function killFocus(): void { if (_textfield.stage.focus == _textfield) _textfield.stage.focus = null; }
		
		private function _onGainFocus(e: Event): void {
			_isFocus = true;
			if (_content == '') _textfield.text = ''; //clear hint
			refreshTheme();
		}
		
		private function _onLooseFocus(e: Event): void {
			_isFocus = false;
			if (_content != _textfield.text) {
				_content = _textfield.text;
				if (_onComplete_Func != null) _onComplete_Func.apply(null, _onComplete_Params);
			}
			
			if (_content == '') _textfield.text = _config.hint;
			refreshTheme();
		}
		
	/********************
	 * 		THEME
	 ********************/
		
		private var _theme		: InputTheme;
		private var oProps		: Object;
		
		public function get themeId():String { return _theme.id; }
		
		public function set themeId(value:String):void {
			if (_theme) _theme.revert2OriginalProps(_textfield, oProps);
			_theme	= InputTheme.getTheme(value);
			oProps	= _theme.saveOriginalProps(_textfield);
			refreshTheme();
		}
	 
		protected function refreshTheme():void {
			if (_config.regExp) _config.regExp.lastIndex = 0;
			_vContent = (!_config.regExp || _config.regExp.test(_content)) ? _content : null;
			
			_theme.apply(_textfield, oProps,	_isFocus		? InputState.INPUT	: 
												_content == ''	? InputState.HINT	: 
												_vContent		? InputState.VALID	: InputState.INVALID
						, _config.maxChars, _config.isPassword );
		}
		
	/********************
	 * 		CONFIG
	 ********************/
		
		private var _config : InputConfig;
			
		public function setConfig(cfg: Object): KInput {
			_config.reset(cfg);
			if (_theme) refreshTheme(); //there might be changes in maxChars or isPassword
			
			return this;
		}
		
		public function setHint(hint: String): KInput {
			_config.hint = hint;
			if (_theme) refreshTheme();
			_onLooseFocus(null);
			return this;
		}
		
	/********************
	 * 		API
	 ********************/
		
		private var _content	: String;
		private var _vContent	: String;
		
		public function get content():String { return _isFocus ? _textfield.text : _content; }
		
		public function set content(value:String):void {
			_content = value || '';
			_textfield.text = _content;
			refreshTheme();
		}
		
		public function get validatedContent(): String {
			if (_isFocus) killFocus();
			return _vContent;
		}
	}
}

import flash.display.DisplayObject;
import flash.display.DisplayObjectContainer;
import flash.text.TextField;
import flash.text.TextFieldType;
import flash.text.TextFormat;
import flash.utils.Dictionary;

class InputState {
	public static const HINT	: int = 0;
	public static const INPUT	: int = 1;
	public static const VALID	: int = 2;
	public static const INVALID	: int = 3;
}

class InputConfig {
	public var isRequired	: Boolean;
	public var trimSpaces	: Boolean;
	public var liveDelay	: Number; // call onInput for every text changes happens in every _liveDelay seconds
	public var hint			: String;
	public var regExp		: RegExp; //array of expressions
	
	public var maxChars		: int;
	public var isPassword	: Boolean;
	
	public function InputConfig() {
		reset( { } );
	}
	
	public function reset(cfg: Object): void {
		hint			= cfg.hint || '';
		isRequired		= cfg.isRequired == true;
		isPassword		= cfg.isPassword == true;
		maxChars		= parseInt(cfg.maxChars);
		trimSpaces		= cfg.trimSpace	!= false;
		regExp			= cfg.regExp;
		
		liveDelay		= parseFloat(cfg.liveDelay || '0.5');
	}
} 


class InputTheme {
	private static var dict			: Dictionary;
	private static var defaultTheme	: InputTheme;
	
	public static function newTheme(id: String, hint: Object, input:Object, valid:Object, invalid:Object, useAsDefault: Boolean = false): InputTheme {
		if (!dict) dict = new Dictionary();
		if (dict[id]) trace('[InputTheme :: overwritting the existed theme with id=' + id + ']');
		
		var theme : InputTheme = new InputTheme(id, hint, input, valid, invalid);
		dict[id] = theme;
		if (useAsDefault) defaultTheme = theme;
		
		return theme;
	}
	
	public static function getTheme(id: String = null): InputTheme {
		var theme : InputTheme = dict && id ? dict[id] : null;
		if (!theme) {
			if (!defaultTheme) {
				defaultTheme = new InputTheme('default', 
						{ textColor: 0x888888 , italic : true, border: true, borderColor:  0x888888},
						{ textColor: 0x555555, border: true, borderColor: 0x0000ff },
						{ textColor: 0x000000, border: true, borderColor: 0x000000 },
						{ textColor: 0x880000, border: true, borderColor: 0x880000 }														
					);
				
			}
			return defaultTheme;
		}
		return theme;
	}
	
	private var format		: Array;
	public var id			: String;
	
	public function InputTheme(id: String, hint: Object, input:Object, valid:Object, invalid:Object) {
		this.id = id;
		format = [hint || {}, input || {}, valid || {}, invalid || {}];
	}
	
	public function apply(tf: TextField, oProps : Object, type:int, maxChars: int, isPassword: Boolean): void {
		var obj :Object = InputUtils.copyProps(oProps);
		obj = InputUtils.copyProps(format[type], obj);
		InputUtils.formatText(tf, obj);
		
		//some special properties that only apply to non-hint type of specific instance (not affects theme)
		tf.maxChars				= type > 0 ? maxChars : 0;
		tf.displayAsPassword	= isPassword && (type > 0);
	}
	
	public function saveOriginalProps(tf: TextField): Object {
		var propList : Object = { };
		
		//values are not important !
		InputUtils.copyProps(format[0], propList);
		InputUtils.copyProps(format[1], propList);
		InputUtils.copyProps(format[2], propList);
		InputUtils.copyProps(format[3], propList);
		
		return InputUtils.getDefaultProps(tf, propList);
	}
	
	public function revert2OriginalProps(tf: TextField, oProps: Object): void {
		InputUtils.formatText(tf, oProps);
	}
}

class InputUtils {
	
	private static var txtFormat : Object = { bold: 1, italic: 1, underline : 1, color : 1, font : 1, size : 1, align : 1, blockIndent : 1, indent : 1, kerning : 1, leading	: 1, leftMargin : 1, rightMargin : 1, tabStops : 1, letterSpacing : 1, bullet : 1, url : 1, target : 1 };
	
	public static function formatText(txt: TextField, props: Object): TextField {
		var formatObj : Object = { };
		
		for (var prop : String in props) {
			trace('formatting :: ', prop, props[prop]);
			if (prop in txtFormat) {
				formatObj[prop] = props[prop];
			} else {//set direct
				txt[prop] = props[prop];
			}
		}
		
		var tf : TextFormat = txt.getTextFormat();
		for (prop in formatObj) {
			tf[prop] = formatObj[prop];
		}
		txt.setTextFormat(tf);
		txt.defaultTextFormat = tf;
		
		return txt;
	}
	
	public static function copyProps(src: Object, tar: Object = null): Object {
		if (!tar) tar = { };
		for (var s : String in src) { tar[s] = src[s]; }
		return tar;
	}
	
	public static function getDefaultProps(tf: TextField, src: Object): * {
		var tfm		: TextFormat = tf.defaultTextFormat;
		var props	: Object = {};
		
		//trace('here is default props :: ');
		
		for (var s: String in src) {
			props[s] = (s in txtFormat) ? tfm[s] : tf[s];
			//trace('s :: ', s, props[s]);
		}
		
		return props;
	}
	
	public static function getDefaultTextField(): TextField {
		return formatText(new TextField(), { type: TextFieldType.INPUT, multiline: false, width: 150, height: 25, size: 16 } );
	}
	
	public static function setView(parentOrViewProps : Object, view: DisplayObject): void {
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
	}
}
