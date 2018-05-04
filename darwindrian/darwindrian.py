#!/usr/bin/jython

from darwindrian_ui import *

#Assemble gui elements
def start_window():
	root = swing.JFrame(title = 'Darwindrian - prototype')
	content = swing.JPanel(layout = awt.BorderLayout())
	content.add(gui_canvas, awt.BorderLayout.CENTER)
	content.add(gui_control, awt.BorderLayout.SOUTH)
	
	#Issue split bar
	split = swing.JSplitPane(swing.JSplitPane.HORIZONTAL_SPLIT)
	split.setLeftComponent(gui_mini_view)
	split.setRightComponent(content)
	
	#Issue whole arrangment
	top = swing.JPanel(layout = awt.BorderLayout())
	
	top.add(split, awt.BorderLayout.CENTER)
	top.add(gui_status_bar, awt.BorderLayout.SOUTH)
	top.add(gui_menu, awt.BorderLayout.NORTH)
	
	root.contentPane = top
	root.visible = 1
	root.resizable = 0
	root.defaultCloseOperation = swing.JFrame.EXIT_ON_CLOSE
	root.pack()
	
	gui_clear_graph()
	
def testing():
	if __name__ == '__main__':
		start_window()
#run
testing()
