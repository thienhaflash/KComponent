package {
	import flash.display.MovieClip;
	import vn.ui.KMenu;
	
	public class KMenuTest extends MovieClip {
		private var menu : KMenu;
		
		public function KMenuTest() {
			
			new KMenu().reset( this,
				'File', 'Edit','View', 'Search','Debug', 'Project', 'Insert', 'Refactor', 'Tools', 'Macros', 'Syntax', 'Help'
			);
			
			menu = new KMenu(trace)
			.setLevelConfigs(
				{ panelColor: 0xBBBBBB },
				{ panelIsHorz: true, panelX: 0, panelColor: 0xCCCCCC},
				{ panelAlign: 'BL', panelColor: 0xDDDDDD },
				{ panelColor: 0xEEEEEE },
				{ panelColor: 0xFFFFFF }
			).reset({parent: this, x: 100, y: 100}, 
				['File', 
					['New',
						['Blank Document',
							['Blank 1',
								'blank 1.1', 'blank 1.2', 'blank 1.3', 'blank 1.4'],
							'Blank 2', 'Blank 3', 'Blank 4', 'Blank 5'], 
						'AS2 Document', 'AS3 Document',
						['Recently opened', 
							'file1.as', 'file2.as', 'file3.as', 'file4.as']],
					'Modify', 'Open', 'Recent files', 'Recent projects'],
				['Edit',
					'Undo', 'Redo', 'cut', 'copy', 'paste', 'selectAll'],
				'View', 'Search', 'Debug');
			menu.active('@uto1d.1.2');
			menu.keepShowLevel = 2;
		}
	}
}